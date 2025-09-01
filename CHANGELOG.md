## 2.0.0 - Major Architecture Overhaul

### 🎉 Breaking Changes

- **BREAKING**: Migrated from Provider/Riverpod to custom InheritedWidget-based state management
- **BREAKING**: Removed dependency on `flutter_riverpod` and `provider` packages
- **BREAKING**: Updated API patterns for state access

### ✨ New Features

- Custom `NidOcrStateManager` for state management
- `LiveOcrStateBuilder` widget for reactive UI updates
- Context extensions for easy state access (`context.liveOcrState`, `context.ocrController`)
- Generic type-safe state management with `CustomStateManager<T>`
- Migration helpers for smooth transition from v1.x

### 🚀 Improvements

- **Zero External Dependencies**: Pure Flutter InheritedWidget implementation
- **Better Performance**: Optimized state updates and rebuilds
- **Simplified API**: Direct context access without complex provider setup
- **Enhanced Type Safety**: Full generic type support
- **Easier Integration**: No provider configuration required

### 🗂️ File Structure Changes

- Added `/lib/src/module/presentation/state/` - Custom state management
- Removed `/lib/src/module/presentation/providers/` - Old provider-based code
- Updated exports to reflect new architecture

### 📚 Documentation

- Comprehensive README with architecture comparison
- Migration guide from v1.x to v2.x
- Usage examples and API documentation
- State management implementation details

### 🔧 Migration Path

```dart
// OLD (v1.x) - Provider/Riverpod
Consumer<LiveOcrNotifier>(
  builder: (context, notifier, child) => Widget(),
)

// NEW (v2.x) - Custom State Management
LiveOcrStateBuilder(
  builder: (context, state, controller) => Widget(),
)
```

## 1.0.0 - Provider-based Implementation

### ✨ Features

- NID front and back side scanning
- OCR text extraction and validation
- Camera integration with cutout overlay
- Real-time auto OCR processing
- Cross-validation between front and back sides

### 🏗️ Architecture

- Provider/Riverpod-based state management
- `LiveOcrNotifier` for business logic
- Consumer widgets for UI updates

## 0.0.1 - Initial Release

### ✨ Features

- Basic NID scanning functionality
- Initial OCR implementation
- Camera integration
- Basic UI components
