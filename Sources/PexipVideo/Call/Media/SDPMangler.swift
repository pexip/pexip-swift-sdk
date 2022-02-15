import Foundation

/// Responsible for mangling the SDP to set bandwidths and resolutions
struct SDPMangler {
    enum Pattern: String {
        case mediaLine = "^m=(\\w*)\\s.*$"
        case connectionLine = "^c=.*$"
        case codecH264ProfileLevel52 = "^a=fmtp:.*;profile-level-id=\\w{4}34$"
    }

    enum Constants {
        static let videoOrientation = "urn:3gpp:video-orientation"
        static let endOfLine = "\r\n"
    }

    let sdp: String

    func sdp(withBandwidth bandwidth: UInt, isPresentation: Bool) -> String {
        let mediaLinePredicate = NSPredicate(pattern: .mediaLine)
        let connectionLinePredicate = NSPredicate(pattern: .connectionLine)
        let profileLevelPredicate = NSPredicate(pattern: .codecH264ProfileLevel52)
        let lines = sdp.components(separatedBy: Constants.endOfLine)
        var modifiedLines = [String]()
        var section = "global"

        for var line in lines {
            guard line.range(of: Constants.videoOrientation) == nil else {
                continue
            }

            let isVideoSection = section == "video"

            if mediaLinePredicate.evaluate(with: line) {
                let delimeters = CharacterSet(charactersIn: "= ")
                let components = line.components(separatedBy: delimeters)
                if components.count > 1 {
                    section = components[1]
                }
            }

            // HACK: remove once H264 Level 5.2 is supported in Pexip Infinity v21+ (see MI-1758)
            if isVideoSection && profileLevelPredicate.evaluate(with: line) {
                // change 34 to 33 at the end of the line (0x34 = 52 is 5.2, 0x33 = 51 is 5.1)
                line = line.dropLast(2) + "33"
            }

            modifiedLines.append(line)

            if isVideoSection && connectionLinePredicate.evaluate(with: line) {
                if bandwidth != 0 {
                    modifiedLines.append("b=AS:\(bandwidth)")
                }

                if isPresentation {
                    modifiedLines.append("a=content:slides")
                }
            }
        }

        return modifiedLines.joined(separator: Constants.endOfLine)
    }
}

// MARK: - Private extensions

private extension NSPredicate {
    convenience init(pattern: SDPMangler.Pattern) {
        self.init(format: "SELF MATCHES %@", pattern.rawValue)
    }
}
