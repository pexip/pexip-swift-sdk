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

import Vision

/// Performs person segmentation in an image using Vision framework.
@available(iOS 15.0, *)
@available(macOS 12.0, *)
public final class VisionPersonSegmenter: PersonSegmenter {
    private let requestHandler: VNSequenceRequestHandler

    private lazy var segmentationRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()

    // MARK: - Init

    public init(requestHandler: VNSequenceRequestHandler = .init()) {
        self.requestHandler = requestHandler
    }

    // MARK: - Perform Requests

    public func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        try? requestHandler.perform([segmentationRequest], on: pixelBuffer)
        return segmentationRequest.results?.first?.pixelBuffer
    }
}
