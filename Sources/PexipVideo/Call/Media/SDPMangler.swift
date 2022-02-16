import Foundation

/// Responsible for mangling the SDP to set bandwidths and resolutions
struct SDPMangler {
    let sdp: String

    func mangle(qualityProfile: QualityProfile, isPresentation: Bool) -> String {
        var modifiedLines = [String]()
        var section = Constants.sectionGlobal
        var addBandwidth = true
        var addContentSlides = isPresentation
        var opusRtpmap: String?
        let lines = sdp.components(separatedBy: Constants.delimeter).filter({ !$0.isEmpty })

        for line in lines {
            section = Regex.media.matchEntire(line)?.groupValue(at: 1) ?? section
            opusRtpmap = Regex.opusRtpmap.matchEntire(line)?.groupValue(at: 1) ?? opusRtpmap

            let isVideoSection = section == Constants.sectionVideo

            // swiftlint:disable opening_brace
            if let rtpmap = opusRtpmap,
               let opusBitrate = qualityProfile.opusBitrate,
               line.isMediaFormatParameterLine(rtpmap)
            {
                var parameters = line.mediaFormatParameters()

                for (index, parameter) in parameters.enumerated()
                where parameter.key == Constants.opusMaxAverageBitrate {
                    parameters[index] = .init(key: parameter.key, value: "\(opusBitrate * 1000)")
                }

                let modifiedLine = Constants.mediaFormatParameter
                    + ":\(rtpmap) "
                    + parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ";")

                modifiedLines.append(modifiedLine)
                opusRtpmap = nil
            } else {
                modifiedLines.append(line)
            }

            if !line.starts(with: "c=") {
                continue
            }

            if addBandwidth && isVideoSection {
                modifiedLines.append("b=AS:\(qualityProfile.bandwidth)")
                addBandwidth = false
            }

            if addContentSlides && isVideoSection {
                modifiedLines.append("a=content:slides")
                addContentSlides = false
            }
        }

        return modifiedLines
            .joined(separator: Constants.delimeter)
            .appending(Constants.delimeter)
    }
}

// MARK: - Private types

private enum Constants {
    static let sectionGlobal = "global"
    static let sectionAudio = "audio"
    static let sectionVideo = "video"
    static let mediaFormatParameter = "a=fmtp"
    static let opusMaxAverageBitrate = "maxaveragebitrate"
    static let delimeter = "\r\n"
}

extension Regex {
    static let media = Regex("^m=(\(Constants.sectionVideo)|\(Constants.sectionAudio)).*$")
    static let opusRtpmap = Regex("^a=rtpmap:(\\d+)\\s+\\b(opus).*$")
}

// MARK: - Private extensions

private extension String {
    struct MediaFormatParameter {
        let key: String
        let value: String
    }

    func isMediaFormatParameterLine(_ rtpmap: String) -> Bool {
        rtpmap.isEmpty ? false : starts(with: "\(Constants.mediaFormatParameter):\(rtpmap)")
    }

    func mediaFormatParameters() -> [MediaFormatParameter] {
        components(separatedBy: " ")
            .dropFirst(1)
            .joined(separator: "")
            .components(separatedBy: ";")
            .compactMap {
                let parts = $0.components(separatedBy: "=")
                return parts.count == 2
                    ? MediaFormatParameter(key: parts[0], value: parts[1])
                    : nil
            }
    }
}
