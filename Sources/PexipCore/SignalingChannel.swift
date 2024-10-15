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

import Foundation
import Combine

/// The object responsible for setting up and controlling a communication session.
public protocol SignalingChannel: AnyObject {
    /// The publisher that publishes incoming signaling events.
    var eventPublisher: AnyPublisher<SignalingEvent, Never> { get }

    /// The list of ice servers.
    var iceServers: [IceServer] { get }

    // The call ID (if present)
    var callId: String? { get async }

    /// The object responsible for sending and receiving arbitrary data messages.
    var data: DataChannel? { get }

    /**
     Sends a new local SDP.

     - Parameters:
        - callType: The type of the call ("WEBRTC" for a WebRTC call).
        - description: The new local SDP
        - presentationInMain: Controls whether or not the participant sees
                              presentation in the layout mix.

     - Returns: The new SDP answer
     */
    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String?

    /**
     Invoked when offer is set and the connection is ready to accept media.

     - Parameters:
        - description: Optional SDP answer
     */
    func ack(_ description: String?) async throws

    /**
     Sends a new ICE candidate if doing trickle ICE.

     - Parameters:
        - candidate: Representation of address in candidate-attribute format as per RFC5245.
        - mid: The media stream identifier tag.
     */
    func addCandidate(_ candidate: String, mid: String?) async throws

    /**
     Sends a sequence of DTMF signals

     - Parameters:
        - signals: The DTMF signals to send
     */
    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool

    /**
     Specifies the aspect ratio the participant would like to receive.
     - Parameters:
        - aspectRatio: The preferred aspect ratio
     */
    @discardableResult
    func setPreferredAspectRatio(_ aspectRatio: Float) async throws -> Bool

    /**
     Mutes or unmutes a participant's video.

     - Parameters:
        - muted: `true` to mute the video, `false` to unmute the video.
     */
    @discardableResult
    func muteVideo(_ muted: Bool) async throws -> Bool

    /**
     Mutes or unmutes a participant's audio.

     - Parameters:
        - muted: `true` to mute the audio, `false` to unmute the audio.
     */
    @discardableResult
    func muteAudio(_ muted: Bool) async throws -> Bool

    /// Requests to take presentation floor.
    @discardableResult
    func takeFloor() async throws -> Bool

    /// Requests to release presentation floor.
    @discardableResult
    func releaseFloor() async throws -> Bool
}
