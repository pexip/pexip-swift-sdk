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

/// The max bandwidth of a video stream (512...6144)
@available(*, deprecated, message: "Use ``Bitrate`` type instead.")
public struct Bandwidth: RawRepresentable, Hashable {
    /// The max bandwidth of a video stream.
    public let rawValue: UInt

    /**
     Creates a new instance of ``Bandwidth``.

     - Parameters:
        - rawValue: the max bandwidth of a video stream (512...6144)
     */
    public init?(rawValue: UInt) {
        if (512...6144).contains(rawValue) {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }

    // MARK: - Default values

    /// Up to 512 kbps
    public static let low = Bandwidth(rawValue: 512)!

    /// Up to 1264 kbps
    public static let medium = Bandwidth(rawValue: 1264)!

    /// Up to 2464 kbps
    public static let high = Bandwidth(rawValue: 2464)!

    /// Up to 6144 kbps
    public static let veryHigh = Bandwidth(rawValue: 6144)!
}
