import 'package:bd_ekyc/exports.dart';

/// Wrapper that provides NidScanManager for the front scan screen
class NidFrontScanScreen extends StatelessWidget {
  const NidFrontScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NidScanManager(child: const _NidFrontScanScreenContent());
  }
}

class _NidFrontScanScreenContent extends StatefulWidget {
  const _NidFrontScanScreenContent();

  @override
  State<_NidFrontScanScreenContent> createState() => _NidFrontScanScreenState();
}

class _NidFrontScanScreenState extends State<_NidFrontScanScreenContent>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final GlobalKey _cameraKey = GlobalKey();
  bool _isInitializing = false;
  bool _hasAutoCaptureFired = false;
  bool _isReadyForScan = false; // Ready for scan state
  bool _cameraDisposed = false; // Camera disposal state
  NidScanResult? _capturedFrontResult; // Store captured result
  String? _lastErrorMessage; // Track last error to prevent multiple popups

  // Cutout size (optimized for NID cards)
  final double cutoutWidth = 340;
  final double cutoutHeight = 220;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset camera and state using our custom state management
      if (mounted) {
        context.scanController.setCameraInitialized(false);
        context.scanController.setCameraController(null);
        _reinitializeEverything();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Stop OCR timer first to prevent async operations
    try {
      context.scanController.stopAutoOcr();
    } catch (e) {
      // Ignore if context is already disposed
      debugLog("OCR stop failed during dispose: $e");
    }

    // Dispose camera controller
    _controller?.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      context.scanController.stopAutoOcr();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller?.initialize();

      if (mounted) {
        setState(() {});
        context.scanController.setCameraInitialized(true);
        context.scanController.setCameraController(_controller);

        // Don't start auto OCR immediately - wait for ready button
        debugLog("Camera initialized for front side scan");
      }
    } catch (e) {
      debugLog("Camera initialization error: $e");
      if (mounted) {
        context.scanController.setError("Camera Error: $e");
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _autoCapture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _hasAutoCaptureFired) {
      return;
    }

    _hasAutoCaptureFired = true;
    debugLog("Auto-capturing front side image when green success detected");

    final ocrState = context.scanController;

    // Stop auto OCR during capture
    ocrState.stopAutoOcr();

    final capturedFile = await ocrState.captureAndCrop(
      controller: _controller!,
      cutoutWidth: cutoutWidth,
      cutoutHeight: cutoutHeight,
      screenWidth: MediaQuery.of(context).size.width,
      screenHeight: MediaQuery.of(context).size.height,
    );

    if (capturedFile != null && mounted) {
      debugLog("Front side image captured, processing and cross-checking");

      // Process the captured image with OCR
      final capturedOcrResult = await ocrState.scanFrontSide(
        context,
        capturedFile,
      );

      if (capturedOcrResult.success) {
        // Cross-check auto-scan data vs captured OCR data
        if (mounted) {
          final autoScanData = context.scanData;
          final isDataMatched = _crossCheckData(
            autoScanData,
            capturedOcrResult,
          );

          if (isDataMatched) {
            debugLog(
              "Auto-scan and captured data match! Front side capture complete",
            );

            // Store the captured result with the image file and dispose camera
            setState(() {
              _capturedFrontResult = capturedOcrResult.copyWith(
                frontSideImageFile: capturedFile,
              );
            });

            debugLog(
              "Front result stored with image file: ${capturedFile.path}",
            );
            debugLog("Camera disposal status: $_cameraDisposed");

            // Dispose camera after successful capture
            _disposeCamera();

            debugLog("Camera disposed, should show captured result now");
          } else {
            debugLog("Data mismatch between auto-scan and captured image");
            _showErrorDialog("Data verification failed. Please try again.");
            _hasAutoCaptureFired = false; // Allow retry
            // Restart auto OCR
            if (_controller != null && _controller!.value.isInitialized) {
              ocrState.startAutoOcr(_controller!);
            }
          }
        }
      } else {
        // Show error and allow retry
        _showErrorDialog(
          capturedOcrResult.errorMessage ?? "Front side scan failed",
        );
        _hasAutoCaptureFired = false; // Allow retry
        // Restart auto OCR
        if (_controller != null && _controller!.value.isInitialized) {
          ocrState.startAutoOcr(_controller!);
        }
      }
    } else {
      debugLog("Front side capture failed");
      _hasAutoCaptureFired = false; // Allow retry
      // Restart auto OCR
      if (_controller != null && _controller!.value.isInitialized) {
        ocrState.startAutoOcr(_controller!);
      }
    }
  }

  bool _crossCheckData(dynamic autoScanState, NidScanResult capturedResult) {
    // Simple cross-check logic - can be enhanced
    // For now, just check if both have valid data
    if (capturedResult.nidNumber == null || capturedResult.nidNumber!.isEmpty) {
      return false;
    }
    if (capturedResult.nidName == null || capturedResult.nidName!.isEmpty) {
      return false;
    }
    if (capturedResult.nidDateOfBirth == null ||
        capturedResult.nidDateOfBirth!.isEmpty) {
      return false;
    }

    debugLog("Cross-check passed: Valid NID data found in captured image");
    return true;
  }

  Future<void> _reinitializeEverything() async {
    debugLog("🔄 Reinitializing everything...");

    setState(() {
      _lastErrorMessage = null;
      _isReadyForScan = false;
      _cameraDisposed = false;
      _hasAutoCaptureFired = false;
      _capturedFrontResult = null;
    });

    // Stop and reset OCR
    context.scanController.stopAutoOcr();
    context.scanController.reset();

    // Reset state
    context.scanController.setCameraInitialized(false);
    context.scanController.setCameraController(null);

    // Dispose current camera
    await _controller?.dispose();
    _controller = null;

    // Reinitialize camera
    await _initCamera();
  }

  void _prepareForScan() {
    setState(() {
      _isReadyForScan = true;
      _lastErrorMessage = null;
    });

    // Start OCR only when ready
    if (_controller != null && _controller!.value.isInitialized) {
      context.scanController.startAutoOcr(_controller!);
    }
  }

  void _disposeCamera() {
    context.scanController.stopAutoOcr();
    _controller?.dispose();
    _controller = null;

    setState(() {
      _cameraDisposed = true;
    });

    // Delay state updates to avoid rebuild conflicts
    Future.microtask(() {
      if (mounted) {
        context.scanController.setCameraInitialized(false);
        context.scanController.setCameraController(null);
      }
    });
  }

  void _showErrorDialog(String error) {
    // Prevent multiple error dialogs for the same error
    if (_lastErrorMessage == error) return;
    _lastErrorMessage = error;

    showAlertDialog(
      context,
      alertType: AlertType.error,
      msg: error,

      onButtonPressed: () {
        pop(context);
        _hasAutoCaptureFired = false; // Allow retry
        _lastErrorMessage = null; // Reset to allow new errors
      },
      btnText: "Retry",
    );
  }

  Widget _buildCapturedResultView() {
    if (_capturedFrontResult?.frontSideImageFile == null) {
      debugLog(
        "ERROR: _buildCapturedResultView called but frontSideImageFile is null!",
      );
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              "Error: Image file not found",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    debugLog(
      "Displaying captured image: ${_capturedFrontResult!.frontSideImageFile!.path}",
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.file(
              _capturedFrontResult!.frontSideImageFile!,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Front side captured successfully!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                push(
                  context,
                  NidBackScanScreen(frontScanResult: _capturedFrontResult!),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Scan Back Side"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(OcrScanData ocrState) {
    return Stack(
      children: [
        // Full screen camera preview
        Positioned.fill(child: CameraPreview(_controller!, key: _cameraKey)),

        // Overlay with cutout
        Positioned.fill(
          child: CustomPaint(
            painter: CutoutOverlayPainter(
              cutoutWidth: cutoutWidth,
              cutoutHeight: cutoutHeight,
              overlayColor: Colors.black.withValues(alpha: 0.7),
              borderColor: ocrState.hasValidNidData
                  ? Colors.green.withValues(alpha: .4)
                  : Colors.white,
              borderWidth: ocrState.hasValidNidData ? 4.0 : 3.0,
            ),
          ),
        ),

        // Instructions at the top
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Scan NID Front Side",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Place the front side of your NID card within the frame",
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Error display
        if (ocrState.errorMessage?.isNotEmpty == true)
          Positioned(
            top: 160,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ocrState.errorMessage ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.scanController.clearError();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Ready for scan button (shown when camera is ready but not scanning)
        if (!_isReadyForScan &&
            !ocrState.isProcessing &&
            _capturedFrontResult == null)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _prepareForScan,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Ready for Scan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Status indicator
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ocrState.isProcessing
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Processing front side...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ocrState.hasValidNidData
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Valid front side detected! Capturing...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : _isReadyForScan
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Looking for front side...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Press 'Ready for Scan' to begin",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        // OCR Result Display (for debugging)
        if (ocrState.ocrText?.isNotEmpty == true)
          Positioned(
            left: 12,
            right: 12,
            bottom: 260,
            top: 260,
            child: OcrResultDisplay(ocrState: ocrState),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NidScanBuilder(
      builder: (context, ocrState, controller) {
        final isCameraInitialized = context.isCameraInitialized;

        // Auto-capture when valid front side data is detected and ready for scan
        if (ocrState.hasValidNidData &&
            !_hasAutoCaptureFired &&
            _isReadyForScan) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoCapture();
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text("NID Front Side Scan"),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _reinitializeEverything,
                icon: const Icon(Icons.restart_alt),
                tooltip: "Refresh & Restart",
              ),
            ],
          ),
          body: _cameraDisposed && _capturedFrontResult != null
              ? (() {
                  debugLog("Build: Showing captured result view");
                  return _buildCapturedResultView();
                })()
              : !isCameraInitialized
              ? (() {
                  debugLog(
                    "Build: Showing loading screen - camera not initialized",
                  );
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          "Initializing Camera...",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                })()
              : (() {
                  debugLog("Build: Showing camera view");
                  return _buildCameraView(ocrState);
                })(),
        );
      },
    );
  }
}
