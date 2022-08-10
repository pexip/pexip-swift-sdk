import CoreImage

public extension CGImage {
    static func image(
        width: Int = 1,
        height: Int = 1
    ) -> CGImage? {
        #if os(iOS)
        let color = CIColor(color: .red)
        #else
        let color = CIColor(color: .red)!
        #endif

        return CIContext().createCGImage(
            CIImage(color: color),
            from: CGRect(x: 0, y: 0, width: width, height: height)
        )
    }
}
