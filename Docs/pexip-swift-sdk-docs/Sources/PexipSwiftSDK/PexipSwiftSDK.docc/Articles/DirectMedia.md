# Direct Media

Join end-to-end "direct media" RTP calls with **Pexip Swift SDK**.

## Overview

When enabled, direct media feature works out-of-the-box, but there are a few conference events
that need to be handled in the app.

## Implementation

### Enable or disable direct media

Direct media is disabled by default. If the feature is supported by the client app, 
set `directMedia` flag on `ConferenceTokenRequestFields` to `true` when requesting a token.

```swift
import PexipInfinityClient

do {
    let conferenceService = infinityService.node(url: node).conference(alias: alias)
    let fields = ConferenceTokenRequestFields(
        displayName: "Guest",
        directMedia: true // false
    )
    let token = try await conferenceService.requestToken(
        fields: fields,
        pin: nil
    )
} catch let error as ConferenceTokenError {
    // The server might respond with a pin challenge, require SSO or conference extension.
    // Check ConferenceTokenError documentation to read more about all possible error types.
} catch {
    // ...
}
```

### Chat

Chat messages are being sent via the data channel when on a direct media WebRTC call. 
This functionality is implemented under the hood and doesn't require any changes in the app.

### Splash screen event

Handle splash screen events if you want to display the conference background image 
and current status text message:

```swift
conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .splashScreen(let event):
                let text = event.elements.first(where: { $0.isTextType })?.text
                let backgroundUrl = splashScreen.background.url
            // ...
            }
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```

### Peer disconnected event

Re-create the media connection when another peer is disconnected from a direct media call.

```swift
conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .peerDisconnected:
                // 1. Stop the current media connection
                mediaConnection.stop()

                // 2. Create new media connection
                mediaConnection = mediaFactory.createMediaConnection(
                    config: mediaConnectionConfig
                )

                // 3. Subscribe to media connection events
                sinkMediaConnectionEvents()

                // 4. Set your local audio and video tracks on the new media connection object
                mediaConnection.setMainAudioTrack(mainLocalAudioTrack)
                mediaConnection.setMainVideoTrack(cameraVideoTrack)
                
                // 5. Start the media connection
                try await mediaConnection.start()
            // ...
            }
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```

### Refer event (call transfer)

Re-create both conference and media connection objects on `refer` event 
in order to be transferred from direct media to transcoded call and back. 
This event is sent when more participants join or leave the conference. 
See <doc:CallTransfer> for more details.
