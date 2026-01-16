# Opus-iOS

iOS build scripts for the [Opus Codec](http://www.opus-codec.org) - a totally open, royalty-free, highly versatile audio codec.

## Features

- ✅ XCFramework with proper Apple Silicon support
- ✅ iOS Device (arm64)
- ✅ iOS Simulator (arm64 for Apple Silicon + x86_64 for Intel)
- ✅ Swift Package Manager support
- ✅ CocoaPods support
- ✅ Minimum iOS 16.0

## Installation

### Swift Package Manager (Recommended)

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/OnBeep/Opus-iOS.git", from: "1.9.0")
]
```

Or in Xcode:
1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/OnBeep/Opus-iOS.git`
3. Select the version and add to your target

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'Opus-ios', '~> 1.9'
```

Then run:

```bash
pod install
```

### Manual Integration

1. Build the XCFramework (see [Building the Library](#building-the-library))
2. Drag `dependencies/opus.xcframework` into your Xcode project
3. Ensure it's added to your target's **Frameworks, Libraries, and Embedded Content**

## Usage

### Swift

```swift
import opus

// Create encoder
var error: Int32 = 0
let encoder = opus_encoder_create(48000, 2, OPUS_APPLICATION_VOIP, &error)

// Encode audio
let frameSize: Int32 = 960 // 20ms at 48kHz
var encodedData = [UInt8](repeating: 0, count: 4000)
let pcmData: [Int16] = [] // Your PCM audio samples
let encodedBytes = opus_encode(encoder, pcmData, frameSize, &encodedData, 4000)

// Clean up
opus_encoder_destroy(encoder)
```

### Objective-C

```objc
#import <opus/opus.h>

// Create encoder
int error;
OpusEncoder *encoder = opus_encoder_create(48000, 2, OPUS_APPLICATION_VOIP, &error);

// Encode audio
int frameSize = 960; // 20ms at 48kHz
unsigned char encodedData[4000];
opus_int16 *pcmData = ...; // Your PCM audio samples
int encodedBytes = opus_encode(encoder, pcmData, frameSize, encodedData, 4000);

// Clean up
opus_encoder_destroy(encoder);
```

## Building the Library

If you need to rebuild the library from source:

### Prerequisites

- Xcode Command Line Tools
- Internet connection (to download Opus source if not cached)

### Step 1: Configure Version

Edit `build-libopus.sh` to set your desired versions:

```bash
VERSION="1.5.2"        # Opus version
SDKVERSION="26.0"      # iOS SDK version (run `xcodebuild -showsdks` to check)
MINIOSVERSION="16.0"   # Minimum iOS deployment target
```

### Step 2: Build

```bash
./build-libopus.sh
```

This will:
1. Download the Opus source tarball (or use cached version from `build/src/`)
2. Cross-compile for iOS Device (arm64)
3. Cross-compile for iOS Simulator (arm64 + x86_64)
4. Create an XCFramework at `dependencies/opus.xcframework`

The build uses `/tmp` for compilation to avoid permission issues with system directories.

### Step 3: Verify

```bash
# Check XCFramework structure
ls -la dependencies/opus.xcframework/

# Verify device architecture (arm64)
lipo -info dependencies/opus.xcframework/ios-arm64/opus.framework/opus

# Verify simulator architectures (arm64 + x86_64)
lipo -info dependencies/opus.xcframework/ios-arm64_x86_64-simulator/opus.framework/opus
```

## Opus Codec Features

- **Sampling rates**: 8 to 48 kHz
- **Bit-rates**: 6 kb/s to 510 kb/s
- **Channels**: Mono, Stereo, up to 255 channels
- **Frame sizes**: 2.5 ms to 60 ms
- **Applications**: VoIP, video conferencing, in-game chat, live music

## Troubleshooting

### Apple Silicon Simulator Error (Fixed in v1.9+)

If you see:
```
Building for 'iOS-simulator', but linking in object file built for 'iOS'
```

**Solution**: Update to version 1.9+ which includes an XCFramework with proper Apple Silicon simulator support.

For older versions, you can:
1. Run the simulator with Rosetta (Product → Destination → Destination Architectures → Show Rosetta Destinations)
2. Rebuild the library using the updated `build-libopus.sh` script

### SDK Version Mismatch

If the build fails with "no such sysroot directory", check your installed SDK:

```bash
ls /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/
```

Update `SDKVERSION` in `build-libopus.sh` to match your installed SDK.

### Permission Issues

The build script uses `/tmp` for compilation to avoid permission issues. If you still encounter problems:

```bash
# Check ownership of build directory
ls -la build/

# If owned by root, the build script will automatically use /tmp
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

- [Opus Codec](http://www.opus-codec.org) by Xiph.Org Foundation & Skype
- Original iOS build scripts by [Mike Tigas](https://github.com/mtigas)
- Maintained by [OnBeep](https://github.com/OnBeep)
