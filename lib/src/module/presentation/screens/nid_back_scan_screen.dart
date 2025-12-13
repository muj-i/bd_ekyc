import 'package:bd_ekyc/exports.dart';
import 'package:bd_ekyc/src/module/presentation/widgets/edge_to_edge_config.dart';

/// Wrapper that provides NidScanManager for the back scan screen
class NidBackScanScreen extends StatelessWidget {
  final NidScanResult frontScanResult;

  const NidBackScanScreen({super.key, required this.frontScanResult});

  @override
  Widget build(BuildContext context) {
    return NidScanManager(
      child: _NidBackScanScreenContent(frontScanResult: frontScanResult),
    );
  }
}

class _NidBackScanScreenContent extends StatefulWidget {
  final NidScanResult frontScanResult;

  const _NidBackScanScreenContent({required this.frontScanResult});

  @override
  State<_NidBackScanScreenContent> createState() => _NidBackScanScreenState();
}

class _NidBackScanScreenState extends State<_NidBackScanScreenContent>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final GlobalKey _cameraKey = GlobalKey();
  bool _isInitializing = false;
  bool _hasAutoCaptureFired = false;
  bool _isReadyForScan = false; // Ready for scan state
  bool _cameraDisposed = false; // Camera disposal state
  NidScanResult? _capturedBackResult; // Store captured back result
  String? _lastErrorMessage; // Track last error to prevent multiple popups

  // Cutout size (optimized for NID cards - larger size to fully capture barcode)
  final double cutoutWidth = 440; // Wide enough for full NID card width
  final double cutoutHeight =
      280; // Increased to 280 to fully capture PDF417 barcode at bottom

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      await _controller!.initialize();

      if (mounted) {
        setState(() {});
        context.scanController.setCameraInitialized(true);
        context.scanController.setCameraController(_controller);

        // Don't start auto OCR immediately - wait for ready button
        debugLog("Camera initialized for back side scan");
      }
    } catch (e) {
      debugLog("Camera initialization error: $e");
      if (mounted) {
        _showErrorDialog("Camera initialization failed: $e");
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _reinitializeEverything() async {
    debugLog("🔄 Reinitializing everything...");

    setState(() {
      _lastErrorMessage = null;
      _isReadyForScan = false;
      _cameraDisposed = false;
      _hasAutoCaptureFired = false;
      _capturedBackResult = null;
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

  void _showErrorDialog(String error) {
    // Prevent multiple error dialogs for the same error
    if (_lastErrorMessage == error) return;
    _lastErrorMessage = error;

    // Stop auto OCR immediately
    context.scanController.stopAutoOcr();

    showAlertDialog(
      context,
      alertType: AlertType.error,
      msg: error,

      onButtonPressed: () {
        pop(context);
        // Reinitialize everything - user must tap Ready to Scan again
        _reinitializeEverything();
      },
      btnText: "OK",
    );
  }

  void _prepareForScan() {
    setState(() {
      _isReadyForScan = true;
      _lastErrorMessage = null;
    });

    // Start OCR for back side only when ready
    if (_controller != null && _controller!.value.isInitialized) {
      context.scanController.startAutoOcrForBackSide(
        _controller!,
        widget.frontScanResult,
      );
    }
  }

  void _disposeCamera() async {
    context.scanController.stopAutoOcr();
    await _controller?.dispose();
    _controller = null;

    // Delay state updates to avoid rebuild conflicts
    Future.microtask(() {
      if (mounted) {
        context.scanController.setCameraInitialized(false);
        context.scanController.setCameraController(null);
      }
    });
    setState(() {
      _cameraDisposed = true;
    });
  }

  Future<void> _autoCapture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _hasAutoCaptureFired) {
      return;
    }

    _hasAutoCaptureFired = true;
    debugLog("Auto-capturing back side image when green success detected");

    final ocrState = context.scanController;

    // Stop auto OCR during capture
    ocrState.stopAutoOcr();

    // Use captureAndCropWithOriginal to get both cropped and original images
    // Original image is needed for barcode scanning (barcode may be cut off in cropped image)
    final captureResult = await ocrState.captureAndCropWithOriginal(
      controller: _controller!,
      cutoutWidth: cutoutWidth,
      cutoutHeight: cutoutHeight,
      screenWidth: MediaQuery.of(context).size.width,
      screenHeight: MediaQuery.of(context).size.height,
    );

    final capturedFile = captureResult.croppedFile;
    final originalFile = captureResult.originalFile;

    if (capturedFile != null && mounted) {
      debugLog("Back side image captured, processing and cross-checking");
      debugLog("Original image for barcode: ${originalFile?.path}");

      // Process the captured image with OCR, pass original for barcode scanning
      final capturedOcrResult = await ocrState.scanBackSide(
        context,
        capturedFile,
        widget.frontScanResult,
        originalImageFile: originalFile,
      );

      // Clean up original file after scanning
      if (originalFile != null) {
        try {
          await originalFile.delete();
        } catch (e) {
          debugLog("Error deleting original file: $e");
        }
      }

      if (capturedOcrResult.success) {
        // Cross-check auto-scan data vs captured OCR data
        if (mounted) {
          final autoScanData = context.scanData;
          final isDataMatched = _crossCheckBackData(
            autoScanData,
            capturedOcrResult,
          );

          if (isDataMatched) {
            debugLog(
              "Auto-scan and captured data match! Back side capture complete",
            );

            // Store the captured result with the image file and dispose camera
            setState(() {
              _capturedBackResult = capturedOcrResult.copyWith(
                backSideImageFile: capturedFile,
              );
            });

            debugLog(
              "Back result stored with image file: ${capturedFile.path}",
            );
            debugLog("Camera disposal status: $_cameraDisposed");

            // Dispose camera after successful capture
            _disposeCamera();

            debugLog("Camera disposed, should show captured result now");
          } else {
            debugLog("Data mismatch between auto-scan and captured image");
            _showErrorDialog("Data verification failed. Please try again.");
          }
        }
      } else {
        // Show error - user must tap Ready to Scan again
        _showErrorDialog(
          capturedOcrResult.errorMessage ?? "Back side scan failed",
        );
      }
    } else {
      debugLog("Back side capture failed");
      _showErrorDialog("Failed to capture image. Please try again.");
    }
  }

  bool _crossCheckBackData(
    dynamic autoScanState,
    NidScanResult capturedResult,
  ) {
    // Cross-check logic for back side data
    // Check if we have valid back side data
    if (capturedResult.isSmartNid == true && capturedResult.success != true) {
      debugLog("Cross-check failed: Captured result is not successful");
      return false;
    }

    // Check if we have back side specific data (issue date)
    if (capturedResult.isSmartNid == true &&
        (capturedResult.nidIssueDate == null ||
            capturedResult.nidIssueDate!.isEmpty)) {
      debugLog("Cross-check failed: No issue date found in captured image");
      return false;
    }

    // Validate that we still have the front side data intact
    if (capturedResult.nidNumber == null || capturedResult.nidNumber!.isEmpty) {
      debugLog("Cross-check failed: Front side NID number missing");
      return false;
    }

    debugLog(
      "Cross-check passed: Valid back side data found in captured image",
    );
    debugLog("Issue Date: ${capturedResult.nidIssueDate}");
    debugLog("NID Number: ${capturedResult.nidNumber}");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NidScanBuilder(
      builder: (context, ocrState, controller) {
        final isCameraInitialized = context.isCameraInitialized;

        // Auto-capture when valid back side data is detected and ready for scan
        if (ocrState.hasValidBackData == true &&
            !_hasAutoCaptureFired &&
            _isReadyForScan) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoCapture();
          });
        }

        return EdgeToEdgeConfig(
          builder: (_, _) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text("NID Back Side Scan"),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              actions: [
                IconButton(
                  onPressed: _reinitializeEverything,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: "Refresh & Restart",
                ),
              ],
            ),
            body: _cameraDisposed || _capturedBackResult != null
                ? _buildCapturedResultView()
                : !isCameraInitialized ||
                      _controller == null ||
                      !_controller!.value.isInitialized
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _buildCameraView(ocrState),
          ),
        );
      },
    );
  }

  Widget _buildCapturedResultView() {
    if (_capturedBackResult?.backSideImageFile == null) {
      debugLog(
        "ERROR: _buildCapturedResultView called but backSideImageFile is null!",
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
      "Displaying captured back image: ${_capturedBackResult!.backSideImageFile!.path}",
    );

    return EdgeToEdgeConfig(
      builder: (_, _) => Scaffold(
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
                _capturedBackResult!.backSideImageFile!,
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
                      "Back side captured successfully!",
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
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => NidScanSummaryScreen(
                        frontResult: widget.frontScanResult,
                        backResult: _capturedBackResult!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.summarize),
                label: const Text("View Summary"),
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
      ),
    );
  }

  Widget _buildCameraView(OcrScanData ocrState) {
    // Safety check - if controller is disposed or null, show loading
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _cameraDisposed) {
      debugLog("_buildCameraView: Camera not ready, showing loading");
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!, key: _cameraKey),
          ),
        ),

        // Overlay with cutout
        Positioned.fill(
          child: CustomPaint(
            painter: CutoutOverlayPainter(
              cutoutWidth: cutoutWidth - 80,
              cutoutHeight: cutoutHeight - 40,
              overlayColor: Colors.black.withValues(alpha: 0.7),
              borderColor: ocrState.hasValidBackData == true
                  ? Colors.green.withValues(alpha: .4)
                  : Colors.white,
              borderWidth: ocrState.hasValidBackData == true ? 4.0 : 3.0,
            ),
          ),
        ),

        // Instructions at the top
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Scan NID Back Side",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Place the back side of your NID card within the frame",
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Ready for scan button (shown when camera is ready but not scanning)
        if (!_isReadyForScan && !ocrState.isProcessing)
          Positioned(
            bottom: 140,
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
                        SizedBox(width: 12),
                        Text(
                          "Scanning back side...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ocrState.hasValidBackData == true
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
                          "Valid back side detected! Capturing...",
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
                          "Looking for back side...",
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
}
