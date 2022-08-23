#  Video Filters

Modify the captured video buffer by applying various video filters.

## Built-in filters

Use one of the built-in video filter classes (available on iOS 15.0+ and macOS 12.0+).

```swift
import PexipMedia

let cameraVideoTrack = mediaConnectionFactory.createCameraVideoTrack()
let factory = VideoFilterFactory()

cameraVideoTrack?.videoFilter = factory.gaussianBlur(radius: 30)
cameraVideoTrack?.videoFilter = factory.tentBlur(intensity: 0.3)
cameraVideoTrack?.videoFilter = factory.boxBlur(intensity: 0.3)
cameraVideoTrack?.videoFilter = factory.virtualBackground(
    image: UIImage(named: "background_image")!.cgImage!
)    

```

## Custom filters

1. Implement `VideoFilter` protocol from `PexipMedia` framework

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
let cameraVideoTrack = mediaConnectionFactory.createCameraVideoTrack()
cameraVideoTrack?.videoFilter = CustomVideoFilter()
```
