# NID Scan State Management

Simple state management using Flutter's `InheritedNotifier`.

---

## File Structure

```
entities/
└── ocr_scan_data.dart       # Scan data class

state/
├── nid_scan_controller.dart # Controller (ChangeNotifier)
├── nid_scan_provider.dart   # InheritedNotifier + entry widget
└── nid_scan_extensions.dart # Context extensions
```

---

## Usage

```dart
// Wrap your scan flow
NidScanManager(
  child: YourWidget(),
)

// Access controller
context.scanController.startAutoOcr(cameraController);
context.scanController.stopAutoOcr();

// Read scan data
context.scanData.extractedNidNumber;
context.scanData.isProcessing;
context.isCameraInitialized;

// Builder widget
NidScanBuilder(
  builder: (context, scanData, controller) {
    return Text(scanData.extractedName ?? "Scanning...");
  },
)
```

---

## Classes

| Class | Purpose |
|-------|---------|
| `OcrScanData` | OCR scan results (name, NID, DOB, etc.) |
| `NidScanController` | Controller with state + methods |
| `NidScanProvider` | InheritedNotifier wrapper |
| `NidScanManager` | Entry point widget |
| `NidScanBuilder` | Reactive builder widget |
