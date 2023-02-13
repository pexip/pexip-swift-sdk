//
// Copyright 2022 Pexip AS
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
