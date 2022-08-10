import CoreMedia
import ReplayKit

@available(macOS 11.0, *)
public extension CMSampleBuffer {
    static func stub(
        width: Int = 1920,
        height: Int = 1080,
        displayTime: CMTime = CMClockGetTime(CMClockGetHostTimeClock()),
        pixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        orientation: CGImagePropertyOrientation? = .up
    ) -> CMSampleBuffer {
        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            nil,
            &pixelBuffer
        )

        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = CMTime.zero
        info.duration = CMTime.invalid
        info.decodeTimeStamp = CMTime.invalid

        var formatDesc: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer!,
            formatDescriptionOut: &formatDesc
        )

        var sampleBuffer: CMSampleBuffer?

        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer!,
            formatDescription: formatDesc!,
            sampleTiming: &info,
            sampleBufferOut: &sampleBuffer
        )

        if let orientation = orientation {
            CMSetAttachment(
                sampleBuffer!,
                key: RPVideoSampleOrientationKey as CFString,
                value: orientation.rawValue as CFNumber,
                attachmentMode: 0
            )
        }

        return sampleBuffer!
    }
}
