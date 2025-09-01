# Custom State Management Migration Guide

This document explains how to migrate from Provider-based state management to the custom InheritedWidget-based solution while preserving all business logic.

## Architecture Overview

The custom state management consists of several key components:

### Core Components

1. **`CustomStateManager<T>`** - Generic InheritedWidget for state management
2. **`NidOcrStateManager`** - Main widget that provides OCR state to the widget tree
3. **`NidOcrController`** - Contains all the business logic from `LiveOcrNotifier`
4. **`NidOcrAppState`** - State container that holds all OCR-related state
5. **`NidOcrStateProvider`** - Helper class for easy state access

### Migration Helpers

- **`migration_helpers.dart`** - Extensions and builders to ease migration
- **`LiveOcrStateBuilder`** - Replaces `Consumer<LiveOcrNotifier>`
- **`NidOcrContextExtension`** - Adds convenience methods to BuildContext

## Usage

### 1. Wrap your app with NidOcrStateManager

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NidOcrStateManager(
        child: YourMainScreen(),
      ),
    );
  }
}
```

### 2. Access state in widgets

#### Before (Provider):

```dart
// Reading state
final state = context.read<LiveOcrNotifier>().state;
final notifier = context.read<LiveOcrNotifier>();

// Watching state
Consumer<LiveOcrNotifier>(
  builder: (context, notifier, child) {
    return Text(notifier.state.extractedName ?? '');
  },
)
```

#### After (Custom State Management):

```dart
// Reading state
final state = context.liveOcrState;
final controller = context.ocrController;

// Watching state
LiveOcrStateBuilder(
  builder: (context, state, controller) {
    return Text(state.extractedName ?? '');
  },
)
```

### 3. Controller Methods

All the methods from `LiveOcrNotifier` are available in `NidOcrController`:

- `startAutoOcr(controller)`
- `startAutoOcrForBackSide(controller, frontData)`
- `stopAutoOcr()`
- `captureAndCrop(...)`
- `scanFrontSide(context, imageFile)`
- `scanBackSide(context, imageFile, frontData)`
- `reset()`
- `setError(error)`
- `clearError()`

### 4. State Properties

Access state properties through the context extension:

```dart
// OCR state
final extractedName = context.liveOcrState.extractedName;
final isProcessing = context.liveOcrState.isProcessing;
final hasValidNidData = context.liveOcrState.hasValidNidData;

// Camera state
final isCameraInitialized = context.isCameraInitialized;

// Controller
final controller = context.ocrController;
```

## Business Logic Preservation

All business logic from the original `LiveOcrNotifier` has been preserved:

- ✅ Timer-based auto OCR processing
- ✅ Image capture and cropping
- ✅ Front and back side scanning
- ✅ OCR text processing
- ✅ State management and validation
- ✅ Error handling
- ✅ Resource cleanup

## Key Differences

1. **No Provider dependency** - Uses pure Flutter InheritedWidget
2. **Same API surface** - All methods and properties preserved
3. **Context extensions** - Easier access to state and controller
4. **Builder widgets** - Replace Consumer widgets
5. **Disposal handled** - Automatic cleanup in widget lifecycle

## Migration Steps

1. Replace `ChangeNotifierProvider` with `NidOcrStateManager`
2. Replace `context.read<LiveOcrNotifier>()` with `context.ocrController`
3. Replace `context.read<LiveOcrNotifier>().state` with `context.liveOcrState`
4. Replace `Consumer<LiveOcrNotifier>` with `LiveOcrStateBuilder`
5. Remove Provider imports and dependencies

The business logic remains exactly the same, only the state management mechanism changes.
