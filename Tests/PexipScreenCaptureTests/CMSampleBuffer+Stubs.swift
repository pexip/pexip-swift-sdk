//
// Copyright 2024 Pexip AS
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
extension CMSampleBuffer {
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

    // swiftlint:disable function_body_length
    static func audioStub(sampleRate: Float64 = 44100.0) -> CMSampleBuffer {
        let numFrames: CMItemCount = 1024
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 44100.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        var formatDescription: CMAudioFormatDescription?
        CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )

        let dataSize = numFrames * 2
        let audioData = malloc(dataSize)!
        memset(audioData, 0, dataSize)

        var blockBuffer: CMBlockBuffer?
        CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: audioData,
            blockLength: dataSize,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: dataSize,
            flags: 0,
            blockBufferOut: &blockBuffer
        )

        var sampleBuffer: CMSampleBuffer?
        CMAudioSampleBufferCreateWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer!,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription!,
            sampleCount: numFrames,
            presentationTimeStamp: .zero,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )

        free(audioData)

        return sampleBuffer!
    }
    // swiftlint:enable function_body_length
}
