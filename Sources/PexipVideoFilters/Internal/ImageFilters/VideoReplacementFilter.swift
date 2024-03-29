//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import CoreImage
import AVFoundation

final class VideoReplacementFilter: ImageFilter {
    var onReadyToPlay: (() -> Void)?

    private let url: URL
    private let notificationCenter: NotificationCenter
    private var player: AVPlayer?
    private var playerItemOutput: AVPlayerItemVideoOutput?
    private var isPlaying = false
    private var lastFrameImage: CIImage?
    private var playerItemObserver: NSKeyValueObservation?
    private var tracksObserver: NSKeyValueObservation?
    private var playerPlayToEndObserver: NSObjectProtocol?

    // MARK: - Init

    init(
        url: URL,
        notificationCenter: NotificationCenter = .default
    ) {
        self.url = url
        self.notificationCenter = notificationCenter
    }

    deinit {
        stop()
    }

    // MARK: - ImageFilter

    func processImage(
        _ image: CIImage,
        withSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        if !isPlaying {
            try? play()
        }

        let newImage = self.currentVideoImage(
            forSize: size,
            orientation: orientation
        )

        self.lastFrameImage = newImage ?? self.lastFrameImage

        return self.lastFrameImage
    }

    private func play() throws {
        guard !isPlaying else {
            return
        }

        isPlaying = true

        let playerItem = AVPlayerItem(url: url)
        tracksObserver = playerItem.observe(\.tracks) { [weak self] item, _ in
            for track in item.tracks where track.assetTrack?.mediaType == .audio {
                track.isEnabled = false
            }
            self?.tracksObserver?.invalidate()
        }

        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        playerItemObserver = playerItem.observe(\.status) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            self?.playerItemObserver = nil

            let playerItemOutput = AVPlayerItemVideoOutput()
            item.add(playerItemOutput)

            self?.playerItemOutput = playerItemOutput
            self?.player?.rate = 1
            self?.onReadyToPlay?()
        }

        playerPlayToEndObserver = notificationCenter.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.rate = 1
        }
    }

    private func stop() {
        player?.rate = 0
        player = nil
        playerItemOutput = nil
        playerItemObserver = nil
        tracksObserver = nil
        lastFrameImage = nil
        isPlaying = false

        if let playerPlayToEndObserver {
            notificationCenter.removeObserver(playerPlayToEndObserver)
        }

        playerPlayToEndObserver = nil
    }

    private func currentVideoImage(
        forSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        guard let playerItemOutput else {
            return nil
        }

        let itemTime = playerItemOutput.itemTime(forHostTime: CACurrentMediaTime())

        guard playerItemOutput.hasNewPixelBuffer(forItemTime: itemTime) else {
            return nil
        }

        guard let pixelBuffer = playerItemOutput.copyPixelBuffer(
            forItemTime: itemTime,
            itemTimeForDisplay: nil
        ) else {
            return nil
        }

        return CIImage(cvPixelBuffer: pixelBuffer)
            .scaledToFill(size)
            .oriented(orientation)
    }
}
