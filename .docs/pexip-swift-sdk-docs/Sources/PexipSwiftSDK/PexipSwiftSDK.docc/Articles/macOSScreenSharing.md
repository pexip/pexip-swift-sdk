# Screen Sharing on macOS

Stream desktop content like displays, apps, and windows in a conference call using **Pexip Swift SDK**.

## Overview

**Pexip Swift SDK** utilizes [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit) to capture screen content on macOS 12.3+ and [Quartz Window Services API](https://developer.apple.com/documentation/coregraphics/quartz_window_services) on older macOS versions.

## Implementation

### Retrieve the displays and windows for screen capture

```swift
import PexipScreenCapture

let enumerator = ScreenMediaSource.createEnumerator()
let displays = try await enumerator.getShareableDisplays()
let windows = try await enumerator.getShareableWindows()

// Choose first available display
let screenMediaSource = ScreenMediaSource.display(displays.first!)
```

### Start screen capture

```swift
import PexipMedia
import PexipRTC
import PexipScreenCapture

let mediaFactory = WebRTCMediaFactory(logger: DefaultLogger.mediaWebRTC)

// 1. Create a new screen media track.
let screenMediaTrack = mediaFactory.createScreenMediaTrack(
    mediaSource: screenMediaSource
)

// 2. Start screen capture and send presentation video to all conference participants.
mediaConnection.setScreenMediaTrack(screenMediaTrack)
try await screenMediaTrack.startCapture(withVideoProfile: .presentationVeryHigh)
```

### Subscribe to status updates

Screen capture might be stopped due to different reasons, so it could be useful to subscribe to status updates from the screen media track.

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

### Stop screen capture

```swift
screenMediaTrack.stopCapture()
mediaConnection.setScreenMediaTrack(nil)
```
