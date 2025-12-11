# BD EKYC - Flutter NID OCR Package

A comprehensive Flutter package for Bangladesh National ID (NID) card scanning using OCR technology. This package provides end-to-end NID verification with front and back side scanning, data extraction, and validation.

## Features

- ✅ **Front Side NID Scanning** - Extract name, NID number, date of birth
- ✅ **Back Side NID Scanning** - Extract issue date and validate with front side data
- ✅ **Real-time OCR Processing** - Auto-detection with timer-based scanning
- ✅ **Image Capture & Cropping** - Precise cutout-based image extraction
- ✅ **Cross-validation** - Data consistency checks between front and back sides
- ✅ **Smart & Old NID Support** - Compatible with both NID formats
- ✅ **Custom State Management** - Built with InheritedWidget architecture
- ✅ **Camera Integration** - Real-time camera preview with overlay guidance
- ✅ **Zero External Dependencies** - Pure Flutter InheritedWidget
- ✅ **Type Safe** - Full generic type support with compile-time safety

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  bd_ekyc:
    git:
      url: https://github.com/muj-i/bd_ekyc.git
      ref: master
```

Then run:
```bash
flutter pub get
```

## Getting Started

### Basic Setup

**IMPORTANT:** Wrap `NidOcrStateManager` around `MaterialApp` to ensure state is available across all routes.

```dart
import 'package:flutter/material.dart';
import 'package:bd_ekyc/bd_ekyc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NidOcrStateManager(
      child: MaterialApp(
        title: 'BD E-Kyc',
        home: BdEkyc(), // The package entry point
      ),
    );
  }
}
```

**Why wrap MaterialApp?**
- The state manager must be above `MaterialApp` to provide state to all navigated routes
- When you navigate to scan screens using `Navigator.push`, they need access to the state
- This ensures `LiveOcrStateBuilder` and context extensions work in all screens

## Usage Examples

### 1. Basic NID Scanning Flow

```dart
import 'package:bd_ekyc/bd_ekyc.dart';

// The package handles the complete flow:
// 1. Camera initialization
// 2. Front side scanning
// 3. Back side scanning
// 4. Data validation and summary

// Simply wrap your app with BdEkyc widget
BdEkyc()
```

### 2. Custom Integration with State Access

```dart
import 'package:bd_ekyc/exports.dart';

class CustomScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LiveOcrStateBuilder(
      builder: (context, ocrState, controller) {
        return Column(
          children: [
            Text('Extracted Name: ${ocrState.extractedName ?? "Scanning..."}'),
            Text('NID Number: ${ocrState.extractedNidNumber ?? "Scanning..."}'),
            Text('DOB: ${ocrState.extractedDateOfBirth ?? "Scanning..."}'),

            if (ocrState.isProcessing)
              CircularProgressIndicator(),

            ElevatedButton(
              onPressed: () => controller.reset(),
              child: Text('Reset Scan'),
            ),
          ],
        );
      },
    );
  }
}
```

### 3. Accessing State with Context Extensions

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Direct access using context extensions
    final extractedName = context.liveOcrState.extractedName;
    final isProcessing = context.liveOcrState.isProcessing;
    final controller = context.ocrController;

    return Column(
      children: [
        Text('Name: ${extractedName ?? "Not detected"}'),
        if (isProcessing) Text('Processing...'),
        ElevatedButton(
          onPressed: () => controller.startAutoOcr(cameraController),
          child: Text('Start Scanning'),
        ),
      ],
    );
  }
}
```

## State Management API

### Core Components

#### NidOcrStateManager

The root widget that provides state management to the widget tree. **Must wrap MaterialApp** to ensure state is available across all routes.

```dart
// ✅ CORRECT - Wraps MaterialApp
NidOcrStateManager(
  child: MaterialApp(
    home: YourApp(),
  ),
)

// ❌ WRONG - State won't be available in navigated routes
MaterialApp(
  home: NidOcrStateManager(
    child: YourApp(),
  ),
)
```

#### LiveOcrStateBuilder

Builder widget for reactive UI updates.

```dart
LiveOcrStateBuilder(
  builder: (context, ocrState, controller) {
    return YourWidget();
  },
)
```

#### Context Extensions

Convenient access to state and controller.

```dart
// State access
context.liveOcrState          // Current OCR state
context.isCameraInitialized   // Camera status
context.nidOcrState          // Full app state

// Controller access
context.ocrController        // OCR controller instance
```

### Controller Methods

```dart
final controller = context.ocrController;

// OCR Control
controller.startAutoOcr(cameraController);
controller.startAutoOcrForBackSide(cameraController, frontData);
controller.stopAutoOcr();

// Image Processing
controller.captureAndCrop(...);
controller.scanFrontSide(context, imageFile);
controller.scanBackSide(context, imageFile, frontData);

// State Management
controller.reset();
controller.setError(message);
controller.clearError();
```

## Architecture

This package uses a custom state management solution built on Flutter's `InheritedWidget`. This provides:

- **No external dependencies** - Pure Flutter implementation
- **Type-safe state access** - Compile-time safety with generics
- **Optimized rebuilds** - Only affected widgets rebuild
- **Simple API** - Context extensions for easy access

### Widget Hierarchy

```
NidOcrStateManager (Must wrap MaterialApp)
  └─ MaterialApp
      └─ Your App
          └─ All screens have access to OCR state
```

## Package Structure

```
lib/
├── bd_ekyc.dart                           # Main entry point
├── exports.dart                           # Public API exports
└── src/
    ├── core/
    │   ├── config/                        # Configuration files
    │   └── utils/                         # Utility functions
    ├── module/
    │   ├── domain/
    │   │   ├── entities/                  # Data models
    │   │   │   ├── live_ocr_state.dart
    │   │   │   └── nid_scan_result.dart
    │   │   └── services/                  # OCR services
    │   │       └── nid_ocr_service_complete.dart
    │   └── presentation/
    │       ├── screens/                   # UI screens
    │       │   ├── kyc_entry.dart
    │       │   ├── nid_front_scan_screen.dart
    │       │   ├── nid_back_scan_screen.dart
    │       │   └── nid_scan_summary_screen.dart
    │       ├── state/                     # State management
    │       │   ├── custom_state_manager.dart
    │       │   ├── nid_ocr_state_manager.dart
    │       │   ├── nid_ocr_state_provider.dart
    │       │   └── migration_helpers.dart
    │       └── widgets/                   # Reusable widgets
    │           ├── cutout_overlay_painter.dart
    │           └── ocr_result_display.dart
```

## Key Features Explained

### OCR Processing
- **Auto-detection** - 2-second intervals for continuous scanning
- **Image preprocessing** - Automatic enhancement for better accuracy
- **Pattern recognition** - Smart extraction of NID-specific data
- **Real-time validation** - Instant feedback on extracted information

### Camera Management
- **Auto-focus** - Intelligent camera focusing for clear captures
- **Precise cropping** - Cutout-based extraction with aspect ratio handling
- **Optimized resolution** - Camera settings tuned for OCR accuracy

### State Management
- **Session persistence** - Maintains state throughout scanning workflow
- **Error recovery** - Graceful handling of camera and OCR errors
- **Memory efficient** - Automatic cleanup of temporary resources

## Requirements

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- Android: minSdkVersion 21
- iOS: 12.0+

### Platform Setup

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for NID scanning</string>
```

## Troubleshooting

### Common Issues

#### ❌ Error: "No CustomStateManager<NidOcrAppState> found in context"

**Cause:** `NidOcrStateManager` is not wrapping `MaterialApp`, or is placed below it in the widget tree.

**Solution:**
```dart
// ✅ CORRECT
return NidOcrStateManager(
  child: MaterialApp(
    home: BdEkyc(),
  ),
);

// ❌ WRONG - Will cause error when navigating
return MaterialApp(
  home: NidOcrStateManager(
    child: BdEkyc(),
  ),
);
```

#### ❌ State not accessible in navigated screens

**Cause:** Same as above - `NidOcrStateManager` must be above `MaterialApp`.

**Solution:** Ensure your app structure follows the correct hierarchy:
```
NidOcrStateManager
  └─ MaterialApp
      └─ BdEkyc (home)
          └─ All navigated screens have access to state
```

#### ❌ Camera not initializing

**Solution:**
1. Check camera permissions in `AndroidManifest.xml` and `Info.plist`
2. Ensure device has camera access enabled
3. Use `mounted` check before accessing context in async callbacks

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or feature requests, please [open an issue](https://github.com/muj-i/bd_ekyc/issues) on GitHub.
