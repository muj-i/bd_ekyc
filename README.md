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

## Architecture Evolution

### Previous Architecture (v1.x) - Provider/Riverpod Based

```dart
// Previous implementation used Provider/Riverpod
final liveOcrStateProvider = StateNotifierProvider<LiveOcrNotifier, LiveOcrState>((ref) {
  final service = ref.watch(nidOcrServiceProvider);
  return LiveOcrNotifier(service);
});

// Usage in widgets
class ScanScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(liveOcrStateProvider);
    final ocrNotifier = ref.read(liveOcrStateProvider.notifier);

    return Consumer(
      builder: (context, ref, child) {
        return SomeWidget();
      },
    );
  }
}
```

**Issues with Previous Architecture:**

- Heavy dependency on Provider/Riverpod packages
- Complex provider setup and configuration
- Tight coupling between UI and provider patterns
- Difficult to customize for different state management needs

### Current Architecture (v2.x) - Custom InheritedWidget Based

```dart
// New implementation uses custom InheritedWidget
// CRITICAL: NidOcrStateManager must wrap MaterialApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NidOcrStateManager(
      child: MaterialApp(
        home: BdEkyc(),
      ),
    );
  }
}

// Usage in widgets (works in all routes)
class ScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LiveOcrStateBuilder(
      builder: (context, ocrState, controller) {
        // Access state directly
        final extractedName = context.liveOcrState.extractedName;
        final ocrController = context.ocrController;

        return SomeWidget();
      },
    );
  }
}
```

**Benefits of New Architecture:**

- ✅ **Zero External Dependencies** - Pure Flutter InheritedWidget
- ✅ **Simplified API** - Direct context access with extensions
- ✅ **Better Performance** - Optimized state updates and rebuilds
- ✅ **Type Safety** - Full generic type support
- ✅ **Easy Integration** - No complex provider setup required
- ✅ **Customizable** - Easy to extend and modify

## Getting Started

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  bd_ekyc: ^2.0.0
```

### Basic Setup

**IMPORTANT:** Wrap `NidOcrStateManager` around `MaterialApp` to ensure state is available across all routes (especially for navigation to scan screens).

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
import 'package:bd_ekyc/src/module/presentation/state/migration_helpers.dart';

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

## Migration Guide (v1.x to v2.x)

### Step 1: Update Dependencies

```yaml
# Remove old dependencies
dependencies:
  # flutter_riverpod: ^2.3.6  # Remove
  # provider: ^6.0.5          # Remove

  bd_ekyc: ^2.0.0 # Update
```

### Step 2: Update Widget Structure

```dart
// OLD (v1.x)
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        home: ConsumerWidget(...),
      ),
    );
  }
}

// NEW (v2.x) - IMPORTANT: Wrap MaterialApp with NidOcrStateManager
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NidOcrStateManager(
      child: MaterialApp(
        home: BdEkyc(),
      ),
    );
  }
}
```

### Step 3: Update State Access

```dart
// OLD (v1.x)
class ScanWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(liveOcrStateProvider);
    final ocrNotifier = ref.read(liveOcrStateProvider.notifier);

    return Consumer(
      builder: (context, ref, child) => SomeWidget(),
    );
  }
}

// NEW (v2.x)
class ScanWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LiveOcrStateBuilder(
      builder: (context, ocrState, controller) {
        return SomeWidget();
      },
    );
  }
}
```

## File Structure

```
lib/
├── bd_ekyc.dart                           # Main package entry point
└── src/
    ├── core/
    │   └── utils/
    │       └── debug_log.dart
    ├── module/
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── live_ocr_state.dart
    │   │   │   └── nid_scan_result.dart
    │   │   └── services/
    │   │       └── nid_ocr_service_complete.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── kyc_entry.dart
    │       │   ├── nid_front_scan_screen.dart
    │       │   ├── nid_back_scan_screen.dart
    │       │   └── nid_scan_summary_screen.dart
    │       ├── state/                      # Custom State Management
    │       │   ├── custom_state_manager.dart
    │       │   ├── nid_ocr_state_manager.dart
    │       │   ├── nid_ocr_state_provider.dart
    │       │   ├── migration_helpers.dart
    │       │   ├── README.md
    │       │   └── MIGRATION_VERIFICATION.md
    │       └── widgets/
    │           ├── cutout_overlay_painter.dart
    │           └── ocr_result_display.dart
```

## Business Logic Features

### OCR Processing

- **Timer-based Auto OCR** - 2-second intervals for continuous scanning
- **Image Preprocessing** - Automatic image enhancement and optimization
- **Text Extraction** - Advanced OCR with pattern recognition
- **Data Validation** - Real-time validation of extracted information

### Camera Management

- **Auto-focus** - Intelligent camera focusing for clear captures
- **Image Cropping** - Precise cutout-based cropping with aspect ratio handling
- **Resolution Control** - Optimized camera settings for OCR accuracy

### State Persistence

- **Session Management** - Maintains state throughout the scanning process
- **Error Recovery** - Automatic recovery from camera and OCR errors
- **Memory Management** - Efficient cleanup of temporary files and resources

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
