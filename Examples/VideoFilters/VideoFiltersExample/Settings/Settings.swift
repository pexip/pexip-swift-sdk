enum Settings {
    enum Filter: String, CaseIterable, Hashable {
        case none = "None"
        case gaussianBlur = "Gaussian Blur"
        case tentBlur = "Tent Blur"
        case boxBlur = "Box Blur"
        case imageBackground = "Image Background"
        case videoBackground = "Video Background"
        case sepiaTone = "Sepia Tone"
        case blackAndWhite = "Black And White"
        case instantStyle = "Instant Style Effect"
        case instantStyleWithGaussianBlur = "Instant Style + Gaussian Blur"
    }

    enum Segmentation: String, CaseIterable, Hashable {
        case vision = "Vision"
        case googleMLKit = "Google ML Kit"
    }
}
