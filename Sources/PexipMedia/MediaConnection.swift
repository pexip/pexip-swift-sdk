//
// Copyright 2022-2024 Pexip AS
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

import AVFoundation
import Combine
import PexipCore

public typealias DTMFSignals = PexipCore.DTMFSignals

/// Observable object that holds references to main and presentation remote video tracks.
public final class RemoteVideoTracks: ObservableObject {
    /// The main remote video track.
    @Published public private(set) var mainTrack: VideoTrack?
    /// The presentation remote video track.
    @Published public private(set) var presentationTrack: VideoTrack?

    /**
     Creates a new instance of ``RemoteVideoTracks`` object.
     - Parameters:
        - mainTrack: The main remote video track
        - presentationTrack: The presentation remote video track
     */
    public init(mainTrack: VideoTrack? = nil, presentationTrack: VideoTrack? = nil) {
        self.mainTrack = mainTrack
        self.presentationTrack = presentationTrack
    }

    @MainActor
    public func setMainTrack(_ track: VideoTrack?) {
        mainTrack = track
    }

    @MainActor
    public func setPresentationTrack(_ track: VideoTrack?) {
        presentationTrack = track
    }
}

/// Media connection between the local computer and a remote peer.
public protocol MediaConnection {
    /// The publisher that publishes state changes.
    var statePublisher: AnyPublisher<MediaConnectionState, Never> { get }

    /// Observable object that holds references to main and presentation remote video tracks.
    var remoteVideoTracks: RemoteVideoTracks { get }

    /// Observable object that holds secure check code.
    /// Check algorithm is triggered on each send / receive of an SDP offer / answer.
    var secureCheckCode: AnyPublisher<String, Never> { get }

    /**
     Sets the given local audio track as the main audio track
     of the media connection and starts sending audio.

     - Parameters:
        - audioTrack: Local audio track
     */
    func setMainAudioTrack(_ audioTrack: LocalAudioTrack?) async throws

    /**
     Sets the given local video track as the main video track
     of the media connection and starts sending video.

     - Parameters:
        - localVideoTrack: Local camera video track
     */
    func setMainVideoTrack(_ videoTrack: CameraVideoTrack?) async throws

    /**
     Sets the given local screen media track as the source for local presentation.

     Call ``ScreenMediaTrack.startCapture`` to start your presentation
     and ``ScreenMediaTrack.stopCapture`` to stop your presentation.

     - Parameters:
        - screenMediaTrack: Local screen media track
     */
    func setScreenMediaTrack(_ screenMediaTrack: ScreenMediaTrack?) async throws

    /**
     Enables or disables the receive of remote audio.

     - Parameters:
        - receive true to receive remote main audio, false otherwise
    */
    func receiveMainRemoteAudio(_ receive: Bool) async throws

    /**
     Enables or disables the receive of remote video.

     - Parameters:
        - receive true to receive remote video audio, false otherwise
     */
    func receiveMainRemoteVideo(_ receive: Bool) async throws

    /// Creates a media session
    func start() async throws

    /// Terminates all media and deallocates resources
    func stop() async

    /**
     Adds or removes remote presentation track from the current media connection.
     Doesn't have any effect if ``MediaConnectionConfig/presentationInMain`` is true.

     - Parameters:
        - receive: True to add remote presentation track, False to remove it.
     */
    func receivePresentation(_ receive: Bool) async throws

    /**
     Sends a sequence of DTMF signals

     - Parameters:
        - signals: The DTMF signals to send
     */
    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool

    /**
     Sets the ``DegradationPreference`` for main video stream.
     If supported, implementations should set ``DegradationPreference/balanced`` as the default.

     - Parameters:
        - preference: a degradation preference
    */
    func setMainDegradationPreference(_ preference: DegradationPreference) async

    /**
     Sets the ``DegradationPreference`` for presentation video stream.
     If supported, implementations should set ``DegradationPreference/balanced`` as the default.

     - Parameters:
        - preference: a degradation preference
    */
    func setPresentationDegradationPreference(_ preference: DegradationPreference) async

    /**
     Sets the maximum bitrate for each video stream.
     Passing an instance of ``Bitrate`` that is equal to zero bits per second will remove the
     constraints and let the underlying media engine come up with the best value.

     By default, no maximum bitrate is set.

     - Parameters:
        - bitrate: a bitrate to set as maximum
    */
    func setMaxBitrate(_ bitrate: Bitrate) async

    /**
     Sets the preferred aspect ratio for remote video.
     - Parameters:
        - aspectRatio: a preferred aspect ratio
     */
    @discardableResult
    func setMainRemoteVideoTrackPreferredAspectRatio(
        _ aspectRatio: Float
    ) async throws -> Bool
}
