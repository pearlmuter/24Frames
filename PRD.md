## Problem Statement

The iPhone's default camera app heavily applies AI computational photography (like Smart HDR and Deep Fusion) to every image. For users who want a pure, untouched image as a foundation for their own editing, these automatic enhancements ruin the capture. There is no simple way to just "take a picture" without this heavy processing on modern iPhones.

## Solution

A minimalist, zero-configuration iOS camera app designed exclusively to output a Base Capture (a high-quality HEIC image with no AI processing). The app strips away all complexity: it uses only the Primary Wide lens, has no options, no zoom, and no Live Photos. The only interaction is tap-to-focus/expose and a single shutter button that provides a Shutter Ring visual feedback.

## User Stories

1. As a photographer, I want to capture photos that bypass Apple's AI enhancements, so that I have a pure Base Capture for post-processing.
2. As a minimalist user, I want an interface with only a shutter button, so that I am not distracted by menus, modes, or options.
3. As a user, I want the camera to be locked to the Primary Wide lens, so that I don't accidentally trigger digital zoom or computational lens switching.
4. As a user, I want to tap the screen to set focus and exposure, so that I have basic creative control over my composition.
5. As a user, I want to see a Shutter Ring animation when taking a photo, so that I have clear visual feedback without a blinding screen flash.
6. As a user, I want my photos saved directly to my iOS Camera Roll, so that I can easily access them in my preferred editing apps.
7. As a user with an older device, I want the app to support iOS 15.0, so that I can use it on my iPhone 13 mini.

## Implementation Decisions

- The app will be built using SwiftUI for the user interface and AVFoundation for the custom camera pipeline.
- The `AVCaptureSession` will be strictly locked to `.builtInWideAngleCamera` (Primary Wide).
- In `AVCapturePhotoSettings`, `isAutoDeferredPhotoDeliveryEnabled` and `isAutoRedEyeReductionEnabled` will be explicitly disabled to prevent AI processing.
- The output format will be HEIC (10-bit color depth) to balance high dynamic range for editing against file size.
- A custom `UIViewRepresentable` will wrap `AVCaptureVideoPreviewLayer` to display the camera feed.
- Tap gestures on the preview layer will be translated into `focusPointOfInterest` and `exposurePointOfInterest` on the `AVCaptureDevice`.
- `PHPhotoLibrary` will be used to write the captured HEIC data directly to the user's photo library.
- Minimum deployment target is set to iOS 15.0.

## Testing Decisions

- A good test isolates external behavior from implementation details. We will focus on testing the configuration state and boundaries rather than the physical camera hardware.
- **CameraManager**: Unit tests will verify that the manager correctly selects the Primary Wide lens and disables computational processing flags upon initialization.
- **PhotoSaver**: Unit tests will inject a mocked `PHPhotoLibrary` to ensure permission handling and save success/failure states are robust.
- **UI / Animation**: XCUITest and SwiftUI Previews will use a mocked `CameraManager` to verify that the Shutter Ring animation triggers correctly upon shutter press.

## Out of Scope

- Digital zoom or pinch-to-zoom gestures.
- Switching to Ultra Wide or Telephoto lenses.
- Live Photos.
- RAW image capture (we are using HEIC).
- In-app gallery or photo review capabilities.
- Settings menu or configurable preferences.
- Screen flash or sound customization.

## Further Notes

- Refer to `CONTEXT.md` for the definitions of Base Capture, Primary Wide, and Shutter Ring.
- ADR `docs/adr/0001-fixed-primary-wide-lens.md` documents the intentional removal of zoom and lens switching.
