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

public final class CoreMLPersonSegmenter: PersonSegmenter {
    private let requestHandler: VNSequenceRequestHandler
    private var request: VNCoreMLRequest?

    // MARK: - Init

    public init?(
        requestHandler: VNSequenceRequestHandler = .init(),
        modelURL: URL
    ) {
        self.requestHandler = requestHandler

        guard let model = try? MLModel(
            contentsOf: modelURL,
            configuration: MLModelConfiguration()
        ) else {
            return nil
        }

        guard let visionModel = try? VNCoreMLModel(for: model) else {
            return nil
        }

        request = VNCoreMLRequest(model: visionModel)
        request?.imageCropAndScaleOption = .scaleFill
        request?.preferBackgroundProcessing = false
    }

    // MARK: - Perform Requests

    public func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let request else {
            return nil
        }

        request.cancel()

        try? requestHandler.perform([request], on: pixelBuffer)

        guard let observation = request.results?.first as? VNPixelBufferObservation else {
            return nil
        }

        return observation.pixelBuffer
    }
}
