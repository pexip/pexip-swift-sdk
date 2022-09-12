# Getting Started with Pexip Swift SDK

Learn how to initiate or connect to conferences hosted on the Pexip Infinity platform.

## Overview

In the SDK there is the concept of a Conference. That Conference handles lots of complexity 
for you like:
- Media signaling
- Conference events from the server
- Token handling

It provides you with all necessary setup to make a conference call. 
The Conference is used to create a WebRTC media connection with Infinity, 
to send and receive video streams.

To do a conference call you will have to go through the following steps:

## Resolve Conferencing Node

The clients need to provide a conference alias and a host address for the desired node. 
The conference alias is typically a SIP address, e.g `conference@example.com`, 
while the host address might be either the same as the conference alias (`example.com`) or a dedicated node on a different location (`someotherurl.com`). 

```swift
import PexipInfinityClient

// 1. Create an instance of NodeResolver
let apiClientFactory = InfinityClientFactory(logger: DefaultLogger.infinityClient)
let nodeResolver = apiClientFactory.nodeResolver(dnssec: false)

// 2. Create a conference alias (force unwrapping is for example only)
let alias = ConferenceAlias(uri: "conference@example.com")!

// 3. Resolve the address of the first available Conferencing Node for the provided host
let node = try await service.resolveNodeURL(
    forHost: alias.host,
    using: nodeResolver
)
```

## Request a conference token

In order to start a `Conference` you need to have a token. You can request a token for 
the conference alias alongside some properties:
- Display name
- Conference extension
- Chosen IDP
- SSO token

The server might respond with a pin challenge. Then you do another call with 
the same properties, and supply a pin as well.


```swift
import PexipInfinityClient

// 1. Create the name by which this participant should be known
let displayName = "Guest"

// 2. Create an instance of InfinityService
let infinityService = apiClientFactory.infinityService()

// 3. Request a token from the Pexip Conferencing Node
do {
    let conferenceService = infinityService.node(url: node).conference(alias: alias)
    // Check ConferenceTokenRequestFields documentation to read more about all possible request properties
    let fields = ConferenceTokenRequestFields(displayName: displayName)
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

## Create a conference 

When requesting a token you will get a response token. The response token is used to 
create a `Conference` along with the node from the previous steps and the conference alias.

```swift
import PexipInfinityClient

// Conference object starts refreshing the token when created.
let conference = apiClientFactory.conference(
    node: node,
    alias: alias,
    token: token
)
```

## Create local media tracks

You can create local audio and video tracks and start capture even before you 
set up `Media Connection` and `Conference`.

```swift
import PexipMedia
import PexipRTC

let mediaFactory = WebRTCMediaFactory(logger: DefaultLogger.mediaWebRTC)

// 1. Create a new local audio track and start audio capture
let audioTrack = mediaFactory.createLocalAudioTrack()
try await audioTrack.startCapture()

// 2. Create a new camera track and start video capture
let cameraVideoTrack = mediaFactory.createCameraVideoTrack()
try await cameraVideoTrack?.startCapture(withVideoProfile: .high)

// 3. Subscribe to capturing status updates
audioTrack.capturingStatus.$isCapturing.receive(on: DispatchQueue.main)
cameraVideoTrack?.capturingStatus.$isCapturing.receive(on: DispatchQueue.main)
```

## Set up media connection

We use WebRTC to do media signaling at the moment. In order to set up the media connection 
you will need:
- An active `Conference` 
- Stun URLs

Use the Stun URLs to create an `Ice Server`. That server is used along with the active `Conference` 
from the previous steps, to create a `Media Connection`. At the same time you can set properties like:
- Video quality (medium, high, etc)
- Presentation In Main

```swift
import PexipMedia
import PexipRTC

let mediaFactory = WebRTCMediaFactory(logger: DefaultLogger.mediaWebRTC)

let config = MediaConnectionConfig(
    signaling: conference.signaling,
    dscp: false,
    presentationInMain: false
)
let mediaConnection = mediaFactory.createMediaConnection(config: config)
```

When having an active `Media Connection` you are able to do things like:
- Set local audio and video tracks
- Start and stop the session

```swift
// 1. Set local audio and video track
mediaConnection.setMainAudioTrack(audioTrack)
mediaConnection.setMainVideoTrack(cameraVideoTrack)

// 2. Start the media connection
try await mediaConnection.start()
```

## Handle media connection events

Listen to media connection events in order to:
- Be notified about media connection state changes
- Receive remote video and presentation tracks

```swift
// 1. Handle state events
mediaConnection.statePublisher
    .sink { event in
        switch event {
        case .new, .connecting:
            print("Connecting...")
        case .connected:
            print("Connected")
        case .failed, .closed, .disconnected:
            print("Disconnected")
        case .unknown:
            break
        }
    }
    .store(in: &cancellables)

// 2. Subscribe to remote video track updates
mediaConnection.remoteVideoTracks.$mainTrack.receive(on: DispatchQueue.main)
mediaConnection.remoteVideoTracks.$presentationTrack.receive(on: DispatchQueue.main)        
```

## Handle conference events

Subscribe to conference events in order to:
- Receive remote presentation from another participant of the conference
- Be notified when the participant is being disconnected from the Pexip side

```swift
conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .conferenceUpdate(let status):
                print(status)
            case .liveCaptions(let captions):
                print(captions)
            case .presentationStart(let message):
                try mediaConnection.receivePresentation(true)
            case .presentationStop:
                try mediaConnection.receivePresentation(false)
            case .clientDisconnected:
                // Leave the conference here
                break
            default:
                // Ignore the rest
                break
            }
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```

## Render video

The media signaling gives the video tracks for you to render in the UI.

**SwiftUI component**:

```swift
import PexipMedia

// Regular
VideoComponent(
    track: mediaConnection.remoteVideoTracks.mainTrack,
    contentMode: .fit16x9,
)

// Vertical video
VideoComponent(
    track: mediaConnection.remoteVideoTracks.presentationTrack,
    contentMode: .fit16x9,
    isReversed: true
)

// Mirrored
VideoComponent(
    track: cameraVideoTrack,
    contentMode: .fitQualityProfile(.high),
    isMirrored: true
)
```

**UIKit view**:

```swift
import PexipMedia

let view = VideoView()
view.isMirrored = true
cameraVideoTrack.setRenderer(view, aspectFit: true)   
```

## Chat

If chat is enabled for the conference, you can send and receive text messages with the help 
of dedicated `Chat` object accessible from the active `Conference`. 

```swift
let chat = conference.chat

// 1. Send a chat message 
try await chat?.sendMessage("Hello world!")

// 2. Receive incoming chat messages
chat?.publisher.sink(receiveValue: { message in
    print("\(message.senderName): \(message.payload)")
}).store(in: &cancellables)
```

## Roster list

Use the `Roster` object to get the full participant list of the conference 
and subscribe to participant updates.

```swift
let roster = conference.roster

// 1. Render the names of all conference participants in SwiftUI
ForEach(roster.participants) { participant in
    Text(participant.displayName)
}

// 2. Subscribe to participant updates
roster.$participants.sink(receiveValue: { prticipants in
    print("Number of participants: \(prticipants.count)")
}).store(in: &cancellables)

roster.eventPublisher.sink(receiveValue: { event in
    switch event {
    case .added(let participant):
        print("\(participant.displayName) joined")
    case .deleted(let participant):
        print("\(participant.displayName) left")
    case .updated, .reloaded:
        break
    }
}
```

## Leave the conference

```swift
// 1. Release the token, unsubscribe from conference events, etc
await conference.leave()

// 2. Terminate all media and deallocate resources
mediaConnection.stop()

// 3. Stop audio/video capture
audioTrack.stopCapture()
cameraVideoTrack?.stopCapture()
```
