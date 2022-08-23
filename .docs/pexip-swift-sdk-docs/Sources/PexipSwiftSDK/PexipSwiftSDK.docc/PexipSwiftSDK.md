# ``PexipSwiftSDK``

@Metadata {
    @DisplayName("Pexip Swift SDK", style: symbol)
}

## Overview

Pexip Swift SDK is a collection of frameworks for self hosted Pexip Infinity installations that enables customers to build bespoke applications for Apple platforms or add Pexip to existing mobile or desktop experiences and workflows.

- Built upon the [Pexip Client REST API for Infinity](https://docs.pexip.com/api_client/api_rest.htm)
- Uses media signaling with [WebRTC](https://webrtc.org)
- Granulated into multiple libraries in order to be flexible and future proof. Pexip might provide other 
media signaling technologies in the future, or Infinity might be interchanged with the next generation APIs from Pexip at some point.

## Products

- **PexipConference** - core components for working with conferences hosted on the Pexip Infinity platform: conference controls, conference events, media signaling and token refreshing.
- **PexipInfinityClient** - a fluent client for Pexip Infinity REST API v2.
- **PexipRTC** - Pexip WebRTC-based media stack for sending and receiving video streams
- **PexipMedia** - core components for working with audio and video
- **PexipUtils** - extensions, utilities and shared components
- **WebRTC** - WebRTC binaries for Apple platforms

## WIP

**Pexip Swift SDK** is still in active development, there will be breaking changes until we reach v1.0.
If you have any questions about the SDK please contact your Pexip representative.

## License

**Pexip Swift SDK** is released under the Apache Software License, version 1.1. 
See [LICENSE](https://github.com/pexip/pexip-swift-sdk/blob/main/LICENSE) for details.
