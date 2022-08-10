import Vision

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

    public init(requestHandler: VNSequenceRequestHandler = .init()) {
        self.requestHandler = requestHandler
    }

    // MARK: - Perform Requests

    public func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        try? requestHandler.perform(
            [segmentationRequest],
            on: pixelBuffer,
            orientation: .right
        )
        return segmentationRequest.results?.first?.pixelBuffer
    }
}

