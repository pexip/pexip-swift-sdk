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

import PexipScreenCapture

/// ``MediaConnectionFactory`` provides factory methods to create screen media tracks.
public protocol ScreenMediaTrackFactory {
    #if os(iOS)

    /**
     Creates a new screen media track.
     - Parameters:
        - appGroup: The app group identifier.
        - broadcastUploadExtension: Bundle identifier of your broadcast upload extension.
        - defaultVideoProfile: The default video quality profile to use
                               when screen capture starts automatically
                               (e.g. from the Control Center on iOS)
     - Returns: A new screen media track
     */
    func createScreenMediaTrack(
        appGroup: String,
        broadcastUploadExtension: String,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack

    #else

    /**
     Creates a new screen media track.
     - Parameters:
        - mediaSource: The source of the screen content (display or window).
        - defaultVideoProfile: The default video quality profile
     - Returns: A new screen media track
     */
    func createScreenMediaTrack(
        mediaSource: ScreenMediaSource,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack

    #endif
}

// MARK: - Protocol extensions

public extension ScreenMediaTrackFactory {
    #if os(iOS)

    /**
     Creates a new screen media track with default video profile .presentationHigh.
     - Parameters:
        - appGroup: The app group identifier.
        - broadcastUploadExtension: Bundle identifier of your broadcast upload extension.
        - defaultVideoProfile: The default video quality profile to use
                               when screen capture starts automatically
                               (e.g. from the Control Center on iOS)
     - Returns: A new screen media track
     */
    @available(*, deprecated, message: "Use createScreenMediaTrack(::defaultVideoProfile) instead.")
    func createScreenMediaTrack(
        appGroup: String,
        broadcastUploadExtension: String
    ) -> ScreenMediaTrack {
        return createScreenMediaTrack(
            appGroup: appGroup,
            broadcastUploadExtension: broadcastUploadExtension,
            defaultVideoProfile: .presentationHigh
        )
    }

    #else

    /**
     Creates a new screen media track with default video profile .presentationHigh.
     - Parameters:
        - mediaSource: The source of the screen content (display or window).
        - defaultVideoProfile: The default video quality profile
     - Returns: A new screen media track
     */
    @available(*, deprecated, message: "Use createScreenMediaTrack(mediaSource:defaultVideoProfile) instead.")
    func createScreenMediaTrack(
        mediaSource: ScreenMediaSource
    ) -> ScreenMediaTrack {
        return createScreenMediaTrack(
            mediaSource: mediaSource,
            defaultVideoProfile: .presentationHigh
        )
    }

    #endif
}
