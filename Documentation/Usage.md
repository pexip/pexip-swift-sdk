# Using Pexip Swift SDK

To make a conference call you will have to go through the following steps:

- [Resolve Conferencing Node](#resolve-conferencing-node)
- [Request a token](#request-a-token)
- [Create a conference](#create-a-conference )
- [Create local media tracks](#create-local-media-tracks)
- [Set up media connection](#set-up-media-connection)
- [Handle media connection events](#handle-media-connection-events)
- [Handle conference events](#handle-conference-events)
- [Render video](#render-video)
- [Leave the conference](#leave-the-conference)

### Resolve Conferencing Node

```swift
import PexipInfinityClient

// 1. Create an instance of NodeResolver
let apiClientFactory = InfinityClientFactory(logger: DefaultLogger.infinityClient)
let nodeResolver = apiClientFactory.nodeResolver(dnssec: false)

// 2. Create a conference alias (force unwrapping is for example only)
let alias = ConferenceAlias(uri: "conference@example.com")!

// 3. Resolves the address of a Conferencing Node for the provided host
let nodes = try await nodeResolver.resolveNodes(for: alias.host)

// 4. Find the first available node
var node: URL?

for node in nodes {
    if try await service.node(url: url).status() {
        node = url
        break
    }
}
```

### Request a token

```swift
import PexipInfinityClient

// 1. Create the name by which this participant should be known
let displayName = "Guest"

// 2. Create an instance of InfinityService
let infinityService = apiClientFactory.infinityService()

// 3. Request a token from the Pexip Conferencing Node
do {
    let conferenceService = infinityService.node(url: node).conference(alias: alias)
    // Check RequestTokenFields documentation to learn about all possible request properties
    let fields = RequestTokenFields(displayName: displayName)
    let token = try await conferenceService.requestToken(
        fields: fields,
        pin: nil
    )
} catch let error as TokenError {
    // The server might respond with a pin challenge, require SSO or conference extension.
    // Check TokenError documentation to learn about all possible error types.
} catch {
    // ...
}
```

### Create a conference 

```swift
import PexipConference

let conferenceFactory = ConferenceFactory(logger: DefaultLogger.conference)
// Conference object starts refreshing the token when created.
let conference = conferenceFactory.conference(
    service: infinityService,
    node: node,
    alias: alias,
    token: token
)
```

### Create local media tracks

```swift
import PexipMedia
import PexipRTC

let mediaConnectionFactory = WebRTCMediaConnectionFactory(logger: DefaultLogger.mediaWebRTC)

// 1. Create a new local audio track and start audio capture
let audioTrack = mediaConnectionFactory.createLocalAudioTrack()
try await audioTrack.startCapture()

// 2. Create a new camera track and start video capture
let cameraVideoTrack = mediaConnectionFactory.createCameraVideoTrack()
try await cameraVideoTrack?.startCapture(profile: .high)

// 3. Subscribe to capturing status updates
audioTrack.capturingStatus.$isCapturing.receive(on: DispatchQueue.main)
cameraVideoTrack?.capturingStatus.$isCapturing.receive(on: DispatchQueue.main)
```

### Set up media connection

```swift
import PexipMedia
import PexipRTC

let mediaConnectionFactory = WebRTCMediaConnectionFactory(logger: DefaultLogger.mediaWebRTC)

// 1. Create media connection
let config = MediaConnectionConfig(
    signaling: conference.signaling,
    iceServers: [IceServer(urls: token.stunUrlStrings)],
    presentationInMain: false
)
let mediaConnection = mediaConnectionFactory.createMediaConnection(config: config)

// 2. Send audio and video
mediaConnection.sendMainVideo(localVideoTrack: cameraVideoTrack)
mediaConnection.sendMainAudio(localAudioTrack: mainLocalAudioTrack)

// 3. Start a media session
try await mediaConnection.start()
```

### Handle media connection events

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

### Handle conference events

```swift
await conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .presentationStart(let message):
                try mediaConnection.startPresentationReceive()
            case .presentationStop:
                try mediaConnection.stopPresentationReceive()
            case .clientDisconnected:
                // Leave the conference here
                break
            }
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```

### Render video

SwiftUI component:

```swift
import PexipMedia

// Regular
VideoComponent(
    track: mediaConnection.remoteVideoTracks.mainTrack,
    contentMode: .fit_16x9,
)

// Vertical video
VideoComponent(
    track: mediaConnection.remoteVideoTracks.presentationTrack,
    contentMode: .fit_16x9,
    isReversed: true
)

// Mirrored
VideoComponent(
    track: cameraVideoTrack,
    contentMode: .fitQualityProfile(.high),
    isMirrored: true
)
```

UIKit view:

```swift
import PexipMedia

let view = VideoView()
view.isMirrored = true
track.setRenderer(view, aspectFit: true)   
```

### Leave the conference

```swift
// 1. Release the token, unsubscribe from conference events, etc
try await conference.leave()

// 2. Terminate all media and deallocate resources
mediaConnection.stop()

// 3. Stop audio/video capture
audioTrack.stopCapture()
cameraVideoTrack?.stopCapture()
```
