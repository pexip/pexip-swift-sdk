# Call Transfer

Transfer a participant to another conference.

## Overview

The current participant can be transferred to another conference, either by the host or 
when transitioning from direct media to transcoded call and back. In this case both conference 
and media connection objects need to be re-created on `refer` event.

```swift
conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .refer(let event):
                // 1. Leave the current conference (release token, unsubscribe from events, etc)
                await conference.leave()
                
                // 2. Stop media connection
                mediaConnection.stop()
                
                // 3. Request new conference token using the one time token from the event
                let alias = ConferenceAlias(uri: event.alias)!
                let node = try await infinityService.resolveNodeURL(
                    forHost: alias.host,
                    using: nodeResolver
                )
                let conferenceService = infinityService.node(url: node).conference(alias: alias)
                let fields = ConferenceTokenRequestFields(displayName: "Guest")
                let newToken = try await conferenceService.requestToken(
                    fields: fields,
                    incomingToken: event.token
                )

                // 4. Create new conference and media connection objects 
                //    (same as when joining a call)
                let conference = apiClientFactory.conference(
                    node: node,
                    alias: alias,
                    token: token
                )
                let mediaConnection = mediaFactory.createMediaConnection(config: config)

                // 5. Open another view with newly created conference and media connection objects
                // ...
            // ...
            }
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```
