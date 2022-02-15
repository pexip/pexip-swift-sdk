#if os(iOS)
import UIKit
public typealias VideoView = UIView
#elseif os(macOS)
import AppKit
public typealias VideoView = NSView
#endif

public protocol Call {
    var camera: CameraComponent? { get }
    var audio: AudioComponent? { get }
    var remoteVideo: VideoComponent? { get }

    func close()
}

protocol CallConnection: Call {
    typealias SessionDescription = String

    func createOffer() async throws -> SessionDescription
    func setRemoteDescription(_ sdp: SessionDescription) async throws
}

// protocol MediaConnection {
//    typealias SessionDescription = String
//
//    func createOffer() async throws -> SessionDescription
//    func setRemoteDescription(_ sdp: SessionDescription)
//
//    func startCapture(withProfile: CallQualityProfile) async throws
//    func stopCapture() async throws
//    func toggleCamera() async throws
//
//    var isMicrophoneMuted: Bool { get set }
//    func speakerOn()
//    func speakerOff()
//
//    func setLocalVideoRenderer(_ renderer: VideoView)
//    func setRemoteVideoRenderer(_ renderer: VideoView)
// }

// MARK: - Video

public protocol VideoComponent {
    @MainActor func render(to view: VideoView)
    @MainActor func mute(_ isMuted: Bool) async throws
}

// MARK: - Camera

public protocol CameraComponent: VideoComponent {
    @MainActor func toggleCamera() async throws
}

// MARK: - Audio

public protocol AudioComponent {
    var isMuted: Bool { get set }
    func speakerOn()
    func speakerOff()
}
