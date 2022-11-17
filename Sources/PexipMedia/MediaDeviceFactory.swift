public protocol MediaDeviceFactory {
    func videoInputDevices() throws -> [MediaDevice]
}
