import AVFoundation

// MARK: - Format

extension AVCaptureDevice.Format: CaptureDeviceFormat {}

protocol CaptureDeviceFormat {
    var formatDescription: CMFormatDescription { get }
}

extension Array where Element: CaptureDeviceFormat {
    func bestFormat(for qualityProfile: QualityProfile) -> Element? {
        let (width, height) = (Int32(qualityProfile.width), Int32(qualityProfile.height))
        return self.min(by: {
            let dimA = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
            let dimB = CMVideoFormatDescriptionGetDimensions($1.formatDescription)
            let isWidthIncreasing = abs(dimA.width - width) < abs(dimB.width - width)
            let isHeightEqualOrIncreasing = abs(dimA.height - height) <= abs(dimB.height - height)
            return isWidthIncreasing && isHeightEqualOrIncreasing
        })
    }
}

// MARK: - Frame rate

extension AVFrameRateRange: FrameRateRange {}

protocol FrameRateRange {
    var maxFrameRate: Float64 { get }
}

extension Array where Element: FrameRateRange {
    func bestFrameRate(for qualityProfile: QualityProfile) -> UInt {
        guard let closestFrameRate = self.min(by: {
            let fps = Double(qualityProfile.fps)
            return abs($0.maxFrameRate - fps) < abs($1.maxFrameRate - fps)
        }) else {
            return qualityProfile.fps
        }

        return Swift.min(qualityProfile.fps, UInt(closestFrameRate.maxFrameRate))
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
