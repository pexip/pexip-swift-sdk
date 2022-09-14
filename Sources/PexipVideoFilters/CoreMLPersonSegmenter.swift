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
