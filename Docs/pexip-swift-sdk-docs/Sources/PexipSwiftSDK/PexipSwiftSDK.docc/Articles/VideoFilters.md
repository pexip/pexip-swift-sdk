#  Video Filters

Modify the captured video buffer by applying various video filters.

## Built-in filters

### Person segmentation

Use one of the built-in video filters with the default [Vision Person Segmentation](https://developer.apple.com/documentation/vision/vngeneratepersonsegmentationrequest), available on iOS 15.0+ and macOS 12.0+:

```swift
import PexipRTC
import PexipVideoFilters

let mediaFactory = WebRTCMediaFactory()
let filterFactory = VideoFilterFactory()
let cameraVideoTrack = mediaFactory.createCameraVideoTrack()

// 1. Gaussian blur
cameraVideoTrack?.videoFilter = filterFactory.segmentation(
    background: .gaussianBlur(radius: 30)
)

// 2. Tent blur
cameraVideoTrack?.videoFilter = filterFactory.segmentation(
    background: .tentBlur(intensity: 0.3)
)

// 3. Box blur
cameraVideoTrack?.videoFilter = filterFactory.segmentation(
    background: .boxBlur(intensity: 0.3)
)

// 4. Custom image background
cameraVideoTrack?.videoFilter = filterFactory.segmentation(
    background: .image(UIImage(named: "background_image")!.cgImage!)
)    

// 5. Custom video background
cameraVideoTrack?.videoFilter = filterFactory.segmentation(
    background: .video(url: localVideoFileURL)
)

// 6. Custom CIFilter
cameraVideoTrack?.videoFilter = filterFactory.customFilter(
    CIFilter.sepiaTone()
)
```

It's also possible to inject your custom implementation of `PersonSegmenter` protocol,
which might be useful if you want to support video filters on older platforms: 

```swift
import PexipVideoFilters
import MLKit
import MLKitSegmentationSelfie

final class MLKitPersonSegmenter: PersonSegmenter {
    func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let sampleBuffer = sampleBuffer(from: pixelBuffer) else {
            return nil
        }

        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation()

        do {
            let mask = try segmenter.results(in: image)
            return mask.buffer
        } catch {
            return nil
        }
    }
}

cameraVideoTrack?.videoFilter = filterFactory.segmentation(
    segmenter: MLKitPersonSegmenter(),
    background: .gaussianBlur(radius: 30)
)
```

You can find the complete source code in our [Video Filters example app](https://github.com/pexip/pexip-swift-sdk/tree/main/Examples/VideoFilters).

## Custom filters

1. Implement `VideoFilter` protocol from `PexipCore` framework

```swift
import PexipMedia

class CustomVideoFilter: VideoFilter {
    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer {
        // 1. Modify original pixel buffer
        let newPixelBuffer = modify(pixelBuffer, for: orientation)
        // 2. Return the new pixel buffer
        return newPixelBuffer
    }
}
```

2. Set the video filter on your instance of `CameraVideoTrack`

```swift
let cameraVideoTrack = mediaFactory.createCameraVideoTrack()
cameraVideoTrack?.videoFilter = CustomVideoFilter()
```
