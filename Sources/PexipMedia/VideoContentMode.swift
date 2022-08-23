import CoreGraphics

/// Indicates whether the video view should fit or fill the parent context
public enum VideoContentMode: Equatable {
    /// Fit the size of the view by maintaining the aspect ratio (9:16)
    case fit16x9
    /// Fit the size of the view by maintaining the aspect ratio (4:3)
    case fit4x3
    /// Fit the size of the view by maintaining the given aspect ratio
    case fitAspectRatio(CGSize)
    /// Fit the size of the view by maintaining the aspect ratio
    /// from quality profile
    case fitQualityProfile(QualityProfile)
    /// Fill the parent context
    case fill

    public var aspectRatio: CGSize? {
        switch self {
        case .fit16x9:
            return CGSize(width: 16, height: 9)
        case .fit4x3:
            return CGSize(width: 4, height: 3)
        case .fitAspectRatio(let size):
            return size
        case .fitQualityProfile(let qualityProfile):
            return qualityProfile.aspectRatio
        case .fill:
            return nil
        }
    }
}
