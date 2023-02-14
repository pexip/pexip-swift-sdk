# Registration

Register your device to receive calls with **Pexip Swift SDK**.

## Overview

When your Infinity Connect client is registered, you can receive incoming video calls.

While you can use the Registration API in your macOS client apps, it is not recommended to use it on iOS, where the app could be sent to the background and eventually terminated by the system. On iOS use the [PushKit](https://developer.apple.com/documentation/pushkit/responding_to_voip_notifications_from_pushkit) and [CallKit](https://developer.apple.com/documentation/callkit) frameworks to receive incoming Voice-over-IP (VoIP) push notifications and display the system call interface to the user.

## Implementation

### Resolve Conferencing Node

```swift
import PexipInfinityClient

// 1. Create an instance of NodeResolver and InfinityService
let apiClientFactory = InfinityClientFactory(logger: DefaultLogger.infinityClient)
let nodeResolver = apiClientFactory.nodeResolver(dnssec: false)
let infinityService = apiClientFactory.infinityService()

// 2. Create a device alias (force unwrapping is for example only)
let deviceAlias = DeviceAlias(uri: "alias@example.com")!

// 3. Resolve the address of the first available Conferencing Node for the provided host
let node = try await infinityService.resolveNodeURL(
    forHost: deviceAlias.host,
    using: nodeResolver
)
```

### Request a registration token

You need to know your username and password in order to request a registration token.

```swift
import PexipInfinityClient

let registrationToken = try await infinityService.node(url: node)
    .registration(deviceAlias: deviceAlias)
    .requestToken(username: username, password: password)
```

### Create a registration

When requesting a token you will get a response token. The response token is used to 
create a `Registration` along with the node from the previous steps and the device alias.

```swift
import PexipInfinityClient

// Registration object starts refreshing the token when created.
let registration = factory.registration(
    node: node,
    deviceAlias: deviceAlias,
    token: registrationToken
)
```

### Handle registration events

Subscribe to registration events in order to receive incoming calls.

```swift
registration.receiveEvents()

registration.eventPublisher
    .sink { event in
        switch event {
        case .incoming(let incomingCallEvent):
            // Process incoming call event.
            // Display the call interface to the user, etc.
            process(incomingCallEvent)
        case .incomingCancelled(let event):
            // Dismiss the previously presented call interface, etc.
            cancel(event)
        case .failure(let event):
            debugPrint(event.error)
        }
    }
    .store(in: &cancellables)
```

### Accept incoming calls

```swift
// 1. Create the name by which this participant should be known
let displayName = "Guest"

// 2. Create a conference alias (force unwrapping is for example only)
let alias = ConferenceAlias(uri: incomingCallEvent.conferenceAlias)!

// 3. Resolve the address of the first available Conferencing Node for the provided host
let node = try await infinityService.resolveNodeURL(
    forHost: alias.host,
    using: nodeResolver
)

// 4. Request a token from the Pexip Conferencing Node
do {
    let fields = ConferenceTokenRequestFields(displayName: displayName)
    let conferenceToken = try await infinityService.node(url: nodeURL)
        .conference(alias: alias)
        .requestToken(fields: fields, incomingToken: incomingCallEvent.token)
} catch {
    debugPrint(error)
} 
```

The response token can be used to create a Conference object, set up media connection, etc. 
Check <doc:GettingStarted> to learn how to join the conference.
