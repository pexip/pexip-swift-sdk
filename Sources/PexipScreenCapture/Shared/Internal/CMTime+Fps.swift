import CoreMedia

extension CMTime {
    init(fps: UInt) {
        self.init(value: 1, timescale: CMTimeScale(fps))
    }
}
