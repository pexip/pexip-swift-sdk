import CoreVideo
import CoreImage
import PexipMedia
import PexipVideoFilters

enum CameraVideoFilter: String, CaseIterable {
    case none = "None"
    case gaussianBlur = "Gaussian Blur"
    case tentBlur = "Tent Blur"
    case boxBlur = "Box Blur"
    case imageBackground = "Image Background"
}

extension VideoFilterFactory {
    func videoFilter(for filter: CameraVideoFilter) -> VideoFilter? {
        switch filter {
        case .none:
            return nil
        case .gaussianBlur:
            return segmentation(background: .gaussianBlur(radius: 30))
        case .tentBlur:
            return segmentation(background: .tentBlur(intensity: 0.3))
        case .boxBlur:
            return segmentation(background: .boxBlur(intensity: 0.3))
        case .imageBackground:
            if let image = CGImage.withName("background_image") {
                return segmentation(background: .image(image))
            } else {
                return nil
            }
        }
    }
}
