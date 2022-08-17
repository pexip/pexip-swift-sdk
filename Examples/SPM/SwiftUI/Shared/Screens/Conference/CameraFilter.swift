import CoreVideo
import CoreImage
import PexipMedia
import PexipVideoFilters

final class CameraVideoFilter: PexipMedia.VideoFilter {
    enum Kind: String, CaseIterable, Hashable {
        case none = "None"
        case gaussianBlur = "Gaussian Blur"
        case tentBlur = "Tent Blur"
        case boxBlur = "Box Blur"
        case imageBackground = "Image Background"
    }

    private let factory = VideoFilterFactory().background()
    private var videoFilter: PexipVideoFilters.VideoFilter?

    var kind: Kind = .none {
        didSet {
            switch kind {
            case .none:
                videoFilter = nil
            case .gaussianBlur:
                videoFilter = factory.gaussianBlur(radius: 30)
            case .tentBlur:
                videoFilter = factory.tentBlur(intensity: 0.3)
            case .boxBlur:
                videoFilter = factory.boxBlur(intensity: 0.3)
            case .imageBackground:
                if let image = CGImage.withName("background_image") {
                    videoFilter = factory.virtualBackground(image: image)
                } else {
                    videoFilter = nil
                }
            }
        }
    }

    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer {
        videoFilter?.processPixelBuffer(pixelBuffer, orientation: orientation) ?? pixelBuffer
    }
}
