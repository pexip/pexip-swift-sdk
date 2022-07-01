import Vision

@available(iOS 15.0, *)
@available(macOS 12.0, *)
final class VisionPersonSegmenter: PersonSegmenter {
    private let requestHandler = VNSequenceRequestHandler()

    private lazy var segmentationRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()

    // MARK: - Perform Requests

    func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        try? requestHandler.perform(
            [segmentationRequest],
            on: pixelBuffer,
            orientation: .right
        )
        return segmentationRequest.results?.first?.pixelBuffer
    }
}

