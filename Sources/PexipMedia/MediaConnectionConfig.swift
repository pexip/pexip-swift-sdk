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

import PexipCore

/// ``MediaConnection`` configuration.
public struct MediaConnectionConfig {
    /// The list of Google STUN urls
    public static let googleStunUrls = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]
    /// The Google Ice server.
    public static let googleIceServer = IceServer(kind: .stun, urls: googleStunUrls)

    /// The object responsible for setting up and controlling a communication session.
    public let signaling: SignalingChannel

    /// The list of ice servers.
    public let iceServers: [IceServer]

    /// Sets whether DSCP is enabled (default is false).
    ///
    /// DSCP (Differentiated Services Code Point) values mark individual packets
    /// and may be beneficial in a variety of networks to improve QoS.
    ///
    /// See [RFC 8837](https://datatracker.ietf.org/doc/html/rfc8837) for more info.
    public let dscp: Bool

    /// Sets whether presentation will be mixed with main video feed.
    public let presentationInMain: Bool

    /**
     Creates a new instance of ``MediaConnectionConfig``.

     - Parameters:
        - signaling: The object responsible for setting up and controlling a communication session.
        - iceServers: The list of ice servers.
        - dscp: Sets whether DSCP is enabled.
        - presentationInMain: Sets whether presentation will be mixed with main video feed.
     */
    public init(
        signaling: SignalingChannel,
        iceServers: [IceServer] = [],
        dscp: Bool = false,
        presentationInMain: Bool = false
    ) {
        self.signaling = signaling

        var iceServers = (signaling.iceServers + iceServers).filter {
            !$0.urls.isEmpty
        }

        if !iceServers.contains(where: { $0.kind == .stun }) {
            iceServers.append(Self.googleIceServer)
        }

        self.iceServers = iceServers
        self.dscp = dscp
        self.presentationInMain = presentationInMain
    }
}
