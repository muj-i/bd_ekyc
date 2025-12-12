# NID OCR State Management Walkthrough

A comprehensive guide to understanding the custom InheritedWidget-based state management system.

---

## Architecture at a Glance

```mermaid
flowchart TB
    subgraph "Widget Tree"
        A["NidOcrStateManager"]
        B["CustomStateful&lt;NidOcrAppState&gt;"]
        C["CustomStateManager&lt;NidOcrAppState&gt;"]
        D["Your App Screens"]
    end
    
    subgraph "State & Logic"
        E["NidOcrAppState"]
        F["NidOcrController"]
        G["NidOcrServiceComplete"]
    end
    
    A --> B --> C --> D
    C -.->|"provides"| E
    E -->|"contains"| F
    F -->|"uses"| G
    D -->|"context.ocrController"| F
    D -->|"context.liveOcrState"| E
```

---

## The Four Core Components

### 1. CustomStateManager (The Foundation)

The generic `InheritedWidget` that makes state available to descendants.

```mermaid
classDiagram
    class CustomStateManager~T~ {
        +T state
        +Function updateState
        +of(context) CustomStateManager~T~
        +updateShouldNotify() bool
    }
    
    class CustomStateful~T~ {
        +T initialState
        +builder Function
    }
    
    CustomStateful --> CustomStateManager : wraps with
```

| Component | Purpose |
|-----------|---------|
| `CustomStateManager<T>` | InheritedWidget that holds and provides state |
| `CustomStateful<T>` | StatefulWidget that manages state updates |

---

### 2. NidOcrStateManager (The Entry Point)

Wraps your app and initializes everything.

```mermaid
sequenceDiagram
    participant App
    participant NidOcrStateManager
    participant Controller as NidOcrController
    participant Service as NidOcrServiceComplete
    
    App->>NidOcrStateManager: Create widget
    NidOcrStateManager->>Service: Create OCR service
    NidOcrStateManager->>Controller: Create controller(service)
    NidOcrStateManager->>NidOcrStateManager: Build CustomStateful
    Note over NidOcrStateManager: Links controller._updateState<br/>to CustomStateful's setState
```

**Key insight**: The magic happens at line 46-47:
```dart
_controller._updateState = setState;
_controller._currentState = state;
```
This bridges the controller to trigger UI rebuilds!

---

### 3. NidOcrAppState (The State Container)

Holds all OCR-related state in one immutable object.

```mermaid
classDiagram
    class NidOcrAppState {
        +LiveOcrState liveOcrState
        +bool isCameraInitialized
        +CameraController? cameraController
        +NidScanResult? finalScanResult
        +NidOcrController controller
        +copyWith() NidOcrAppState
    }
    
    class LiveOcrState {
        +String? extractedName
        +String? extractedNidNumber
        +String? extractedDateOfBirth
        +bool isProcessing
        +String? errorMessage
        +File? lastCapturedImage
        +bool hasValidNidData
    }
    
    NidOcrAppState --> LiveOcrState : contains
```

---

### 4. NidOcrController (The Business Logic)

Contains all OCR operations and state mutations.

```mermaid
flowchart LR
    subgraph "Controller Methods"
        A[startAutoOcr]
        B[stopAutoOcr]
        C[captureAndCrop]
        D[scanFrontSide]
        E[scanBackSide]
        F[reset]
    end
    
    subgraph "Internal"
        G["_setState()"]
        H["Timer"]
        I["OCR Service"]
    end
    
    A --> H
    H -->|"every 2s"| I
    I --> G
    G -->|"triggers"| J["UI Rebuild"]
    
    C --> I
    D --> I
    E --> I
```

---

## How Data Flows

### Reading State

```mermaid
flowchart LR
    A["Widget"] -->|"1. context.liveOcrState"| B["Extension Method"]
    B -->|"2. NidOcrStateProvider.of(context)"| C["CustomStateManager.of()"]
    C -->|"3. dependOnInheritedWidget"| D["NidOcrAppState"]
    D -->|"4. .liveOcrState"| E["LiveOcrState"]
```

### Updating State

```mermaid
flowchart TB
    A["Widget calls controller method"] -->|"context.ocrController.startAutoOcr()"| B["NidOcrController"]
    B -->|"_setState(updater)"| C["Call _updateState callback"]
    C -->|"setState()"| D["CustomStateful rebuilds"]
    D -->|"New state flows down"| E["CustomStateManager notifies"]
    E -->|"Widgets rebuild"| F["UI Updated"]
```

---

## Lifecycle Management

```mermaid
stateDiagram-v2
    [*] --> Initialized: NidOcrStateManager created
    Initialized --> Ready: initState() creates service & controller
    Ready --> Scanning: startAutoOcr() called
    Scanning --> Processing: Timer fires (every 2s)
    Processing --> Scanning: OCR complete, no valid data
    Processing --> Success: Valid NID data found
    Success --> Ready: reset() called
    Scanning --> Ready: stopAutoOcr() called
    Ready --> [*]: dispose() cleans up
```

---

## Accessing State - Quick Reference

### Using Extensions (Recommended)

```dart
// Get the current OCR state
final state = context.liveOcrState;

// Get the controller
final controller = context.ocrController;

// Check camera status
final isReady = context.isCameraInitialized;
```

### Using Builder Widget

```dart
LiveOcrStateBuilder(
  builder: (context, state, controller) {
    return Column(
      children: [
        Text('Name: ${state.extractedName ?? "Scanning..."}'),
        Text('NID: ${state.extractedNidNumber ?? "---"}'),
        if (state.isProcessing) CircularProgressIndicator(),
      ],
    );
  },
)
```

---

## File Structure

```
state/
├── custom_state_manager.dart    # Generic InheritedWidget foundation
├── nid_ocr_state_manager.dart   # Main entry point + controller + state
├── nid_ocr_state_provider.dart  # Static helper for state access
├── state_extensions.dart        # Context extensions & builders
└── README.md                    # Migration guide
```

---

## Key Takeaways

| Concept | Implementation |
|---------|---------------|
| **State lives in** | `NidOcrAppState` (immutable) |
| **Logic lives in** | `NidOcrController` |
| **State access** | `context.liveOcrState` or `LiveOcrStateBuilder` |
| **State updates** | Controller calls `_setState()` → UI rebuilds |
| **No external deps** | Pure Flutter `InheritedWidget` |

---

## Complete Data Flow Example

```mermaid
sequenceDiagram
    participant UI as Scan Screen
    participant Ext as context.ocrController
    participant Ctrl as NidOcrController
    participant Svc as NidOcrServiceComplete
    participant State as NidOcrAppState
    
    UI->>Ext: Tap capture button
    Ext->>Ctrl: captureAndCrop(...)
    Ctrl->>Ctrl: Take picture
    Ctrl->>Svc: scanFrontSide(image)
    Svc->>Svc: OCR processing
    Svc-->>Ctrl: NidScanResult
    Ctrl->>State: _setState(new state)
    State-->>UI: Widget rebuilds with new data
    UI->>UI: Show extracted info
```
