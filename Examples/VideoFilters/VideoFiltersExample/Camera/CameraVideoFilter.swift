import CoreVideo
import CoreImage
import PexipMedia
import PexipVideoFilters

struct VideoFilter: PexipMedia.VideoFilter {
    private let videoFilter: PexipVideoFilters.VideoFilter

    init(_ videoFilter: PexipVideoFilters.VideoFilter) {
        self.videoFilter = videoFilter
    }

    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer {
        videoFilter.processPixelBuffer(pixelBuffer, orientation: orientation)
    }
}
