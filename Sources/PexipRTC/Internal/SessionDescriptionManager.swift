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

import Foundation
import PexipMedia
import PexipCore

/// Responsible for mangling the SDP to set bandwidths and resolutions
struct SessionDescriptionManager {
    private static let delimeter = "\r\n"
    let sdp: String

    func mangle(
        bitrate: Bitrate,
        mainAudioMid: String? = nil,
        mainVideoMid: String? = nil,
        presentationVideoMid: String? = nil
    ) -> String {
        var modifiedLines = [String]()
        var section = Section.session
        let addBitrate = bitrate.bps > 0

        for line in splitToLines() {
            modifiedLines.append(line)

            switch line {
            case _ where line.starts(with: "m=audio"):
                section = .audio
            case _ where line.starts(with: "m=video"):
                section = .video
            case _ where line.starts(with: "c=IN"):
                if section == .video && addBitrate {
                    modifiedLines.append(String(bitrate: bitrate))
                }
            case mainAudioMid?.toMidLine(), mainVideoMid?.toMidLine():
                modifiedLines.append("a=content:main")
            case presentationVideoMid?.toMidLine():
                modifiedLines.append("a=content:slides")
            default:
                break
            }
        }

        return sdpString(from: modifiedLines)
    }

    func mangle(bitrate: Bitrate) -> String {
        guard bitrate.bps > 0 else {
            return sdp
        }

        var modifiedLines = [String]()

        for line in splitToLines() {
            if let sdpBitrate = line.bitrate, bitrate.bps < sdpBitrate {
                modifiedLines.append(String(bitrate: bitrate))
            } else {
                modifiedLines.append(line)
            }
        }

        return sdpString(from: modifiedLines)
    }

    func extractFingerprints() -> [Fingerprint] {
        let key = "a=fingerprint:"
        return splitToLines()
            .filter({ $0.starts(with: key) })
            .compactMap({ line in
                let parts = line
                    .replacingOccurrences(of: key, with: "")
                    .split(separator: " ", maxSplits: 1)
                if parts.count == 2 {
                    return Fingerprint(
                        type: String(parts[0]),
                        hash: String(parts[1].replacingOccurrences(of: " ", with: ""))
                    )
                } else {
                    return nil
                }
            })
    }

    private func splitToLines() -> [String] {
        sdp.components(separatedBy: Self.delimeter).filter({ !$0.isEmpty })
    }

    private func sdpString(from lines: [String]) -> String {
        lines.joined(separator: Self.delimeter).appending(Self.delimeter)
    }
}

// MARK: - Private types

private enum Section: String {
    case session
    case audio
    case video
}

// MARK: - Private extensions

private extension String {
    func toMidLine() -> String {
        "a=mid:\(self)"
    }

    init(bitrate: Bitrate) {
        self.init("b=TIAS:\(bitrate.bps)")
    }

    var bitrate: UInt? {
        Regex("^b=TIAS:(\\d+)$")
            .match(self)?
            .groupValue(at: 1)
            .flatMap(UInt.init)
    }
}
