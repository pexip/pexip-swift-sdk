#if os(iOS)

struct BroadcastFps {
    static let minValue: UInt = 15
    static let maxValue: UInt = 30

    let value: UInt

    init(value: UInt?) {
        // The broadcast extension has hard memory limit of 50MB.
        // Use lower frame rate to reduce the memory load.
        self.value = min(value ?? Self.minValue, Self.maxValue)
    }
}

#endif
