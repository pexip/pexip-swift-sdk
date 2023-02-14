//
// Copyright 2022 Pexip AS
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

import Combine
import UIKit
import PexipMedia
import PexipRTC
import PexipVideoFilters

final class CameraViewModel: ObservableObject {
    @Published var filterSettings: Settings.Filter = .noFilters
    @Published var segmentationSettings: Settings.Segmentation = .vision
    let video: Video

    private var videoTrack: CameraVideoTrack
    private let filterFactory = VideoFilterFactory()
    private var segmenter: PersonSegmenter = VisionPersonSegmenter()
    private let videoPermission = MediaCapturePermission.video
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        let mediaFactory = WebRTCMediaFactory()
        videoTrack = mediaFactory.createCameraVideoTrack()!
        video = Video(track: videoTrack, contentMode: .fill)

        startCapture()

        $filterSettings.sink { [weak self] newValue in
            self?.videoTrack.videoFilter = self?.videoFilter(for: newValue)
        }.store(in: &cancellables)

        $segmentationSettings.sink { [weak self] newValue in
            guard let self = self else { return }
            self.segmenter = self.segmenter(for: newValue)
            self.videoTrack.videoFilter = self.videoFilter(for: self.filterSettings)
        }.store(in: &cancellables)
    }

    // MARK: - Private

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func videoFilter(
        for filterSettings: Settings.Filter
    ) -> VideoFilter? {
        switch filterSettings {
        case .noFilters:
            return nil
        case .gaussianBlur:
            return filterFactory.segmentation(
                segmenter: segmenter,
                background: .gaussianBlur(radius: 30)
            )
        case .tentBlur:
            return filterFactory.segmentation(
                segmenter: segmenter,
                background: .tentBlur(intensity: 0.3)
            )
        case .boxBlur:
            return filterFactory.segmentation(
                segmenter: segmenter,
                background: .boxBlur(intensity: 0.3)
            )
        case .imageBackground:
            if let image = UIImage(named: "background_image")?.cgImage {
                return filterFactory.segmentation(
                    segmenter: segmenter,
                    background: .image(image)
                )
            } else {
                return nil
            }
        case .videoBackground:
            if let url = Bundle.main.url(
                forResource: "video_background",
                withExtension: "mp4"
            ) {
                return filterFactory.segmentation(
                    segmenter: segmenter,
                    background: .video(url: url)
                )
            } else {
                return nil
            }
        case .sepiaTone:
            return filterFactory.customFilter(CIFilter.sepiaTone())
        case .blackAndWhite:
            return filterFactory.customFilter(CIFilter.photoEffectTonal())
        case .instantStyle:
            return filterFactory.customFilter(CIFilter.photoEffectInstant())
        case .instantStyleWithGaussianBlur:
            return filterFactory.segmentation(
                segmenter: segmenter,
                background: .gaussianBlur(radius: 30),
                filters: [CIFilter.photoEffectInstant()]
            )
        }
    }

    private func segmenter(
        for segmentationSettings: Settings.Segmentation
    ) -> PersonSegmenter {
        switch segmentationSettings {
        case .vision:
            return VisionPersonSegmenter()
        case .googleMLKit:
            return MLKitPersonSegmenter()
        }
    }

    private func startCapture() {
        Task { @MainActor in
            if await videoPermission.requestAccess(
                openSettingsIfNeeded: true
            ) == .authorized {
                try await videoTrack.startCapture(
                    withVideoProfile: .high
                )
            }
        }
    }
}
