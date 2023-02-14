#  Live Captions

Enable live captions when you are on a conference video call.

## Toggle live captions

```swift
var isOn = try await conference.toggleLiveCaptions(true)
```

## Subscribe to live caption events

```swift
await conference.receiveEvents()

conference.eventPublisher
    .sink { event in
        do {
            switch event {
            case .conferenceUpdate(let status):
                // Check if live captions are available
                isOn = status.liveCaptionsAvailable
            case .liveCaptions(let captions):
                if captions.isFinal {
                    print(captions.data)
                }
            // ...
        } catch {
            debugPrint("Cannot handle conference event, error: \(error)")
        }
    }
    .store(in: &cancellables)
```
