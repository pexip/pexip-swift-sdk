# Screen Sharing on iOS

Share your iOS screen (from an iPhone or iPad) in a conference call with **Pexip Swift SDK**.

## Overview

In order to implement screen sharing on iOS with **Pexip Swift SDK**, you will need to utilize [ReplayKit](https://developer.apple.com/documentation/replaykit) and Broadcast Upload Extension. The extension captures the screen content, controls the sharing and communicates with its containing application using the shared [App Group](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups).

## Implementation

### Create Broadcast Upload Extension target

- In Xcode click **File -> New -> Target** and select **Broadcast Upload Extension**

![Broadcast Upload Extension target](iOSScreenSharing1.png)

- Create your new extension target and embed it in your main application. There is no need to include UI Extension since we want to start broadcast session from the app.

![Broadcast Upload Extension dialog](iOSScreenSharing2.png)

- Select the newly created extension target and add **PexipMedia** framework in the **Frameworks and Libraries** section.

### Add App Groups capability

1. Select main app target in the Xcode project.
2. Open **Signing & Capabilities** tab and add **App Groups** capability.
3. Create new App Group with identifier "group.your_app_bundle_id".
4. Repeat the same steps in your Broadcast Upload Extension target.
5. Make sure that both app and extension targets share the same App Group identifier.
6. Update the provisioning profile for your main app and create a new one for the extension target. 

It's also important to select "Audio, AirPlay, and Picture in Picture" in **Signing & Capabilities -> Background Modes** of your main app target.

### Setup broadcast sample handler

Utilize [BroadcastSampleHandler](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipMedia/documentation/pexipmedia/broadcastsamplehandler) from **PexipMedia** framework.

```swift
import ReplayKit
import PexipScreenCapture

final class SampleHandler: RPBroadcastSampleHandler, BroadcastSampleHandlerDelegate {
    private lazy var handler: BroadcastSampleHandler = {
        let handler = BroadcastSampleHandler(appGroup: "your_app_group_id")
        handler.delegate = self
        return handler
    }()

    // MARK: - RPBroadcastSampleHandler

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        handler.broadcastStarted()
    }

    override func broadcastPaused() {
        handler.broadcastPaused()
    }

    override func broadcastResumed() {
        handler.broadcastResumed()
    }

    override func broadcastFinished() {
        handler.broadcastFinished()
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        handler.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }

    // MARK: - BroadcastSampleHandlerDelegate

    func broadcastSampleHandler(
        _ handler: BroadcastSampleHandler,
        didFinishWithError error: Error
    ) {
        // Finish broadcast with user-friendly message.
        super.finishBroadcastWithError(error)
    }
}
```

### Start screen broadcast in the main app

```swift
import PexipMedia
import PexipRTC
import PexipScreenCapture

let mediaFactory = WebRTCMediaFactory(logger: DefaultLogger.mediaWebRTC)

// 1. Create a new screen media track.
let screenMediaTrack = mediaFactory.createScreenMediaTrack(
    appGroup: "your_app_group_id",
    broadcastUploadExtension: "your_broadcast_upload_extension_bundle_id"
)

// 2. Start screen capture and send presentation video to all conference participants.
mediaConnection.setScreenMediaTrack(screenMediaTrack)
try await screenMediaTrack.startCapture(withVideoProfile: .presentationHigh)
```

### Subscribe to status updates

Screen broadcast might be stopped from the iOS control panel or by the system, so it could be useful to subscribe to status updates from the screen media track.

```swift
var isPresenting = false

screenMediaTrack.capturingStatus.$isCapturing
    .receive(on: DispatchQueue.main)
    .sink { isCapturing in
        if !isCapturing && isPresenting {
            mediaConnection.setScreenMediaTrack(nil)
        }

        isPresenting = isCapturing
    }
    .store(in: &cancellables)
```

### Handle conference events

Stop screen capture if presentation has been stolen by another participant.

```swift
await conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .presentationStart(let message):
                screenMediaTrack.stopCapture()
                mediaConnection.setScreenMediaTrack(nil)
                try mediaConnection.receivePresentation(true)
            // ...
            }
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```

### Stop screen broadcast

```swift
screenMediaTrack.stopCapture()
mediaConnection.setScreenMediaTrack(nil)
```
