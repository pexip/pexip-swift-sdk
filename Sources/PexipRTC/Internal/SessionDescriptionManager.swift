import Foundation
import PexipMedia
import PexipCore

/// Responsible for mangling the SDP to set bandwidths and resolutions
struct SessionDescriptionManager {
    private static let delimeter = "\r\n"
    let sdp: String

    func mangle(
        bandwidth: Bandwidth,
        mainQualityProfile: QualityProfile?,
        mainAudioMid: String? = nil,
        mainVideoMid: String? = nil,
        presentationVideoMid: String? = nil
    ) -> String {
        var modifiedLines = [String]()
        var section = "global"
        let mainAudioMidLine = mainAudioMid?.toMidLine()
        let mainVideoMidLine = mainVideoMid?.toMidLine()
        let presentationVideoMidLine = presentationVideoMid?.toMidLine()
        var addBandwidth = true

        for line in splitToLines() {
            section = self.section(for: line) ?? section
            modifiedLines.append(line)

            switch line {
            case mainAudioMidLine, mainVideoMidLine:
                modifiedLines.append("a=content:main")
            case presentationVideoMidLine:
                modifiedLines.append("a=content:slides")
            default:
                let isVideoSection = section == "video"
                let isConnectionLine = line.starts(with: "c=")

                if addBandwidth && isVideoSection && isConnectionLine {
                    modifiedLines.append("b=AS:\(bandwidth.rawValue)")
                    addBandwidth = false
                }
            }
        }

        return modifiedLines
            .joined(separator: Self.delimeter)
            .appending(Self.delimeter)
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

    private func section(for line: String) -> String? {
        Regex("^m=(video|audio).*$")
            .match(line)?
            .groupValue(at: 1)
    }
}

// MARK: - Private extensions

private extension String {
    func toMidLine() -> String {
        "a=mid:\(self)"
    }
}
