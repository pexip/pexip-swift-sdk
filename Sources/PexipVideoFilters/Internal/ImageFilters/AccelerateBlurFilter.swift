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

import Accelerate
import CoreImage

final class AccelerateBlurFilter: ImageFilter {
    enum Kind {
        case tent
        case box
    }

    /// Default blur intensity.
    static let defaultIntensity: Float = 0.4

    /// The maximum kernel length for convolution operations.
    static let maxKernelLength: UInt32 = 51

    private let kind: Kind
    private let ciContext: CIContext
    private let kernelLength: UInt32
    private var lastSize: CGSize = .zero
    private var scaleTempBuffer: UnsafeMutableRawPointer?
    private var blurTempBuffer: UnsafeMutableRawPointer?

    // MARK: - Init

    init(
        kind: Kind,
        intensity: Float = AccelerateBlurFilter.defaultIntensity,
        ciContext: CIContext
    ) {
        let intensity = min(max(intensity, 0), 1)
        var kernelLength = UInt32(floor(intensity * Float(Self.maxKernelLength)))
        kernelLength |= 1

        self.kind = kind
        self.kernelLength = kernelLength
        self.ciContext = ciContext
    }

    deinit {
        scaleTempBuffer?.deallocate()
        scaleTempBuffer = nil
        blurTempBuffer?.deallocate()
        blurTempBuffer = nil
    }

    // MARK: - ImageFilter

    func processImage(
        _ image: CIImage,
        withSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        try? blurredImage(from: image)
    }

    // MARK: - Private

    private func blurredImage(from ciImage: CIImage) throws -> CIImage? {
        let imageSize = ciImage.extent.size

        // 1. Create image buffer
        guard
            let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent),
            let format = vImage_CGImageFormat(cgImage: cgImage)
        else {
            return nil
        }

        func createBuffer() throws -> vImage_Buffer {
            try vImage_Buffer(
                width: Int((Float(imageSize.width) / 4).rounded(.down)),
                height: Int((Float(imageSize.height) / 4).rounded(.down)),
                bitsPerPixel: format.bitsPerPixel
            )
        }

        var imageBuffer = try vImage_Buffer(cgImage: cgImage)
        defer { imageBuffer.free() }

        // 2. Scale down original buffer
        var scaledBuffer = try createBuffer()
        defer { scaledBuffer.free() }

        applyScale(
            source: &imageBuffer,
            destination: &scaledBuffer,
            imageSize: imageSize
        )

        // 3. Apply blur
        var blurredBuffer = try createBuffer()
        defer { blurredBuffer.free() }

        applyBlur(
            source: &scaledBuffer,
            destination: &blurredBuffer,
            imageSize: imageSize
        )

        lastSize = imageSize

        // 4. Scale up and return
        return try CIImage(
            cgImage: blurredBuffer.createCGImage(format: format)
        ).resizedImage(for: imageSize)
    }

    private func applyScale(
        source: UnsafePointer<vImage_Buffer>,
        destination: UnsafePointer<vImage_Buffer>,
        imageSize: CGSize
    ) {
        if imageSize != lastSize {
            let tempBufferSize = vImageScale_ARGB8888(
                source,
                destination,
                nil,
                vImage_Flags(kvImageGetTempBufferSize)
            )
            scaleTempBuffer?.deallocate()
            scaleTempBuffer = malloc(tempBufferSize)
        }

        let noFlags = vImage_Flags(kvImageNoFlags)
        vImageScale_ARGB8888(source, destination, scaleTempBuffer, noFlags)
    }

    private func applyBlur(
        source: UnsafePointer<vImage_Buffer>,
        destination: UnsafePointer<vImage_Buffer>,
        imageSize: CGSize
    ) {
        if imageSize != lastSize {
            let tempBufferSize = blur(
                source: source,
                destination: destination,
                tempBuffer: nil,
                flags: kvImageEdgeExtend | kvImageGetTempBufferSize
            )
            blurTempBuffer?.deallocate()
            blurTempBuffer = malloc(tempBufferSize)
        }

        _ = blur(
            source: source,
            destination: destination,
            tempBuffer: blurTempBuffer,
            flags: kvImageEdgeExtend
        )
    }

    private func blur(
        source: UnsafePointer<vImage_Buffer>,
        destination: UnsafePointer<vImage_Buffer>,
        tempBuffer: UnsafeMutableRawPointer?,
        flags: Int
    ) -> vImage_Error {
        let blur = kind == .tent
            ? vImageTentConvolve_ARGB8888
            : vImageBoxConvolve_ARGB8888

        return blur(
            source,
            destination,
            tempBuffer,
            0, 0,
            kernelLength, kernelLength,
            nil,
            vImage_Flags(flags)
        )
    }
}
