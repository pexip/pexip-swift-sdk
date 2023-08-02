//
// Copyright 2023 Pexip AS
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

/// Represents the number of bits that are conveyed or processed per unit of time.
/// The type is expressed in the unit bit per second.
public struct Bitrate: Equatable {
    /// Bits per second.
    public let bps: UInt

    // MARK: - Init

    private init(bps: UInt) {
        self.bps = bps
    }

    private init?(value: UInt, multiplier: UInt) {
        guard value <= UInt.max / multiplier else {
            return nil
        }
        self.init(bps: value * multiplier)
    }

    // MARK: - Helpers

    /**
     Creates a new instance of ``Bitrate``.

     - Parameters:
        - value: the bitrate in bits per second (bit/s)
     */
    public static func bps(_ value: UInt) -> Bitrate {
        Bitrate(bps: value)
    }

    /**
     Creates a new instance of ``Bitrate``.

     - Parameters:
        - value: the bitrate in kilobits per second (kbit/s)
     */
    public static func kbps(_ value: UInt) -> Bitrate? {
        Bitrate(value: value, multiplier: 1_000)
    }

    /**
     Creates a new instance of ``Bitrate``.

     - Parameters:
        - rawValue: the bitrate in megabits per second (Mbit/s)
     */
    public static func mbps(_ value: UInt) -> Bitrate? {
        Bitrate(value: value, multiplier: 1_000_000)
    }
}
