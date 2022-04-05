import AVFoundation

// MARK: - Format

extension AVCaptureDevice.Format: CaptureDeviceFormat {}

protocol CaptureDeviceFormat {
    var formatDescription: CMFormatDescription { get }
}

extension Array where Element: CaptureDeviceFormat {
    func bestFormat(for qualityProfile: QualityProfile) -> Element? {
        let targetWidth = Int32(qualityProfile.width)
        let targetHeight = Int32(qualityProfile.height)
        var selectedFormat: Element?
        var currentDiff = Int32.max

        for format in self {
            let dimension = CMVideoFormatDescriptionGetDimensions(
                format.formatDescription
            )
            let widthDiff = abs(targetWidth - dimension.width)
            let heightDiff = abs(targetHeight - dimension.height)

            let diff = widthDiff + heightDiff
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = Int32(diff)
            }
        }

        return selectedFormat
    }
}

// MARK: - Frame rate

extension AVFrameRateRange: FrameRateRange {}

protocol FrameRateRange {
    var maxFrameRate: Float64 { get }
}

extension Array where Element: FrameRateRange {
    func bestFrameRate(for qualityProfile: QualityProfile) -> Float64? {
        let targetFrameRate = Float64(qualityProfile.fps)
        var selectedFrameRate: Float64?
        var currentDiff = Float64.greatestFiniteMagnitude

        for frameRateRange in self {
            let diff = abs(frameRateRange.maxFrameRate - targetFrameRate)
            if diff < currentDiff {
                selectedFrameRate = frameRateRange.maxFrameRate
                currentDiff = diff
            }
        }

        return selectedFrameRate
    }
}

// MARK: - Device

extension AVCaptureDevice {
    static func videoCaptureDevices(
        withPosition position: AVCaptureDevice.Position
    ) -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices
    }
}
