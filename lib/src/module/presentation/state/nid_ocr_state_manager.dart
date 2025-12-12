import 'dart:ui' as ui;

import 'package:bd_ekyc/exports.dart';
import 'package:bd_ekyc/src/module/presentation/widgets/edge_to_edge_config.dart';

class NidOcrStateManager extends StatefulWidget {
  final Widget child;

  const NidOcrStateManager({super.key, required this.child});

  @override
  State<NidOcrStateManager> createState() => _NidOcrStateManagerState();
}

class _NidOcrStateManagerState extends State<NidOcrStateManager> {
  late final NidOcrServiceComplete _ocrService;
  late final NidOcrController _controller;

  @override
  void initState() {
    super.initState();
    _ocrService = NidOcrServiceComplete();
    _controller = NidOcrController(_ocrService);
  }

  @override
  void dispose() {
    _controller.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EdgeToEdgeConfig(
      isbottomSafeArea: true,
      builder: (isEdgeToEdge, os) => CustomStateful<NidOcrAppState>(
        initialState: NidOcrAppState(
          liveOcrState: const LiveOcrState(),
          isCameraInitialized: false,
          cameraController: null,
          finalScanResult: null,
          controller: _controller,
        ),
        builder: (context, state, setState) {
          _controller._updateState = setState;
          _controller._currentState = state;
          return widget.child;
        },
      ),
    );
  }
}

class NidOcrAppState {
  final LiveOcrState liveOcrState;
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final NidScanResult? finalScanResult;
  final NidOcrController controller;

  const NidOcrAppState({
    required this.liveOcrState,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.finalScanResult,
    required this.controller,
  });

  NidOcrAppState copyWith({
    LiveOcrState? liveOcrState,
    bool? isCameraInitialized,
    CameraController? cameraController,
    NidScanResult? finalScanResult,
    NidOcrController? controller,
  }) {
    return NidOcrAppState(
      liveOcrState: liveOcrState ?? this.liveOcrState,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      cameraController: cameraController ?? this.cameraController,
      finalScanResult: finalScanResult ?? this.finalScanResult,
      controller: controller ?? this.controller,
    );
  }
}

class NidOcrController {
  final NidOcrServiceComplete _ocrService;
  Timer? _autoOcrTimer;
  bool _isProcessing = false;
  bool _isDisposed = false;

  // This will be set by the state manager
  void Function(NidOcrAppState)? _updateState;

  NidOcrController(this._ocrService);

  void dispose() {
    _isDisposed = true;
    stopAutoOcr();
  }

  NidOcrAppState? _currentState;

  NidOcrAppState _getCurrentState() {
    return _currentState!;
  }

  void _setState(NidOcrAppState Function(NidOcrAppState) updater) {
    if (_updateState != null && !_isDisposed && _currentState != null) {
      final newState = updater(_currentState!);
      _currentState = newState;
      _updateState!(newState);
    }
  }

  /// Start auto OCR processing for back side with timer
  void startAutoOcrForBackSide(
    CameraController controller,
    NidScanResult frontData,
  ) {
    if (_isDisposed) return;
    stopAutoOcr(); // Stop any existing timer

    _autoOcrTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (!_isProcessing && controller.value.isInitialized) {
        await _processOcrForBackSide(controller, frontData);
      }
    });
  }

  /// Start auto OCR processing with timer
  void startAutoOcr(CameraController controller) {
    if (_isDisposed) return;
    stopAutoOcr(); // Stop any existing timer

    _autoOcrTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (!_isProcessing && controller.value.isInitialized) {
        await _processOcr(controller);
      }
    });
  }

  /// Stop auto OCR processing
  void stopAutoOcr() {
    _autoOcrTimer?.cancel();
    _autoOcrTimer = null;
  }

  /// Process OCR from camera for back side
  Future<void> _processOcrForBackSide(
    CameraController controller,
    NidScanResult frontData,
  ) async {
    if (_isDisposed || _isProcessing) return;

    _isProcessing = true;
    if (!_isDisposed) {
      _setState(
        (state) => state.copyWith(
          liveOcrState: state.liveOcrState.copyWith(isProcessing: true),
        ),
      );
    }

    try {
      // Take a picture and process it
      final XFile file = await controller.takePicture();
      final scannedText = await _ocrService.scanTextFromImage(File(file.path));

      if (_isDisposed) return; // Check after async operation

      // Process the OCR text for back side
      final ocrState = _ocrService.processOcrTextForBackSide(
        scannedText,
        frontData,
      );

      // Update state with extracted data
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: ocrState.copyWith(
              isProcessing: false,
              lastCapturedImage: File(file.path),
            ),
          ),
        );
      }

      // Stop auto-OCR if we have valid back side data
      if (!_isDisposed && ocrState.hasValidBackData == true) {
        stopAutoOcr();
        debugLog("✅ Valid back side data found - stopping auto-OCR");
        debugLog(
          "Issue Date: ${_ocrService.extractIssueDateFromBack(scannedText)}",
        );
        debugLog("Front NID: ${frontData.nidNumber}");
        debugLog("Smart NID: ${frontData.isSmartNid}");
      }

      // Clean up the temporary file after a delay
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          if (await File(file.path).exists()) {
            await File(file.path).delete();
          }
        } catch (e) {
          debugLog("Error deleting temp file: $e");
        }
      });
    } catch (e) {
      debugLog("OCR processing error: $e");
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(
              isProcessing: false,
              errorMessage: "Failed to process image: $e",
            ),
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Process OCR from camera
  Future<void> _processOcr(CameraController controller) async {
    if (_isDisposed || _isProcessing) return;

    _isProcessing = true;
    if (!_isDisposed) {
      _setState(
        (state) => state.copyWith(
          liveOcrState: state.liveOcrState.copyWith(isProcessing: true),
        ),
      );
    }

    try {
      // Take a picture and process it
      final XFile file = await controller.takePicture();
      final scannedText = await _ocrService.scanTextFromImage(File(file.path));

      if (_isDisposed) return; // Check after async operation

      // Process the OCR text
      final ocrState = _ocrService.processOcrText(scannedText);

      // Update state with extracted data
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: ocrState.copyWith(
              isProcessing: false,
              lastCapturedImage: File(file.path),
            ),
          ),
        );
      }

      // Stop auto-OCR if we have valid NID data
      final currentState = _getCurrentState();
      if (!_isDisposed && currentState.liveOcrState.hasValidNidData) {
        stopAutoOcr();
        debugLog("✅ Valid NID data found - stopping auto-OCR");
        debugLog("NID: ${currentState.liveOcrState.extractedNidNumber}");
        debugLog("Name: ${currentState.liveOcrState.extractedName}");
        debugLog("DOB: ${currentState.liveOcrState.extractedDateOfBirth}");
      }

      // Clean up the temporary file after a delay
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await File(file.path).delete();
        } catch (e) {
          debugLog("Error deleting temp file: $e");
        }
      });
    } catch (e) {
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(
              isProcessing: false,
              errorMessage: "OCR Error: $e",
            ),
          ),
        );
      }
      debugLog("OCR Error: $e");
    }

    _isProcessing = false;
  }

  /// Manual capture and crop from camera cutout
  Future<File?> captureAndCrop({
    required CameraController controller,
    required double cutoutWidth,
    required double cutoutHeight,
    required double screenWidth,
    required double screenHeight,
  }) async {
    debugLog("Starting captureAndCrop process");

    try {
      final XFile file = await controller.takePicture();
      debugLog("Picture taken successfully: ${file.path}");

      // Load the image and crop it to the cutout area
      final imageFile = File(file.path);
      final croppedFile = await _cropImageToCutout(
        imageFile,
        cutoutWidth,
        cutoutHeight,
        screenWidth,
        screenHeight,
        controller,
      );

      // Delete the original full image to save space
      try {
        await imageFile.delete();
      } catch (e) {
        debugLog("Error deleting original image: $e");
      }

      debugLog("Returning cropped image file: ${croppedFile?.path}");
      return croppedFile;
    } catch (e) {
      debugLog("Capture error: $e");
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(
              errorMessage: "Capture Error: $e",
            ),
          ),
        );
      }
      return null;
    }
  }

  /// Crop image to the cutout area
  Future<File?> _cropImageToCutout(
    File imageFile,
    double cutoutWidth,
    double cutoutHeight,
    double screenWidth,
    double screenHeight,
    CameraController controller,
  ) async {
    try {
      // Read the image bytes
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      debugLog("Original image size: ${image.width} x ${image.height}");
      debugLog("Screen size: $screenWidth x $screenHeight");
      debugLog("Cutout size: $cutoutWidth x $cutoutHeight");

      // Calculate the scaling factors
      final double imageAspectRatio = image.width / image.height;
      final double screenAspectRatio = screenWidth / screenHeight;

      double scaleX, scaleY;
      double offsetX = 0, offsetY = 0;

      if (imageAspectRatio > screenAspectRatio) {
        // Image is wider than screen - fit by height
        scaleY = image.height / screenHeight;
        scaleX = scaleY;
        offsetX = (image.width - screenWidth * scaleX) / 2;
      } else {
        // Image is taller than screen - fit by width
        scaleX = image.width / screenWidth;
        scaleY = scaleX;
        offsetY = (image.height - screenHeight * scaleY) / 2;
      }

      // Calculate cutout position in screen coordinates (center of screen)
      final double cutoutCenterX = screenWidth / 2;
      final double cutoutCenterY = screenHeight / 2;

      // Convert to image coordinates
      final double imageCutoutCenterX = offsetX + cutoutCenterX * scaleX;
      final double imageCutoutCenterY = offsetY + cutoutCenterY * scaleY;

      // Calculate crop rectangle in image coordinates
      final double cropWidth = cutoutWidth * scaleX;
      final double cropHeight = cutoutHeight * scaleY;
      final double cropLeft = imageCutoutCenterX - cropWidth / 2;
      final double cropTop = imageCutoutCenterY - cropHeight / 2;

      // Ensure crop area is within image bounds
      final double adjustedCropLeft = cropLeft.clamp(
        0.0,
        image.width.toDouble(),
      );
      final double adjustedCropTop = cropTop.clamp(
        0.0,
        image.height.toDouble(),
      );
      final double adjustedCropWidth =
          (cropLeft + cropWidth).clamp(0.0, image.width.toDouble()) -
          adjustedCropLeft;
      final double adjustedCropHeight =
          (cropTop + cropHeight).clamp(0.0, image.height.toDouble()) -
          adjustedCropTop;

      debugLog(
        "Crop rectangle: (${adjustedCropLeft.toInt()}, ${adjustedCropTop.toInt()}) ${adjustedCropWidth.toInt()} x ${adjustedCropHeight.toInt()}",
      );

      // Create a picture recorder to draw the cropped image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the cropped portion of the image
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          adjustedCropLeft,
          adjustedCropTop,
          adjustedCropWidth,
          adjustedCropHeight,
        ),
        Rect.fromLTWH(0, 0, adjustedCropWidth, adjustedCropHeight),
        Paint(),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        adjustedCropWidth.toInt(),
        adjustedCropHeight.toInt(),
      );

      // Convert to bytes
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final croppedBytes = byteData!.buffer.asUint8List();

      // Create a temporary file for the cropped image
      final directory = await getTemporaryDirectory();
      final croppedFile = File(
        '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(croppedBytes);

      debugLog("Cropped image saved: ${croppedFile.path}");
      debugLog(
        "Cropped image size: ${adjustedCropWidth.toInt()} x ${adjustedCropHeight.toInt()}",
      );

      // Clean up
      image.dispose();
      croppedImage.dispose();

      return croppedFile;
    } catch (e) {
      debugLog("Cropping error: $e");
      return null;
    }
  }

  /// Complete front side scan
  Future<NidScanResult> scanFrontSide(
    BuildContext context,
    File imageFile,
  ) async {
    if (!_isDisposed) {
      _setState(
        (state) => state.copyWith(
          liveOcrState: state.liveOcrState.copyWith(isProcessing: true),
        ),
      );
    }

    try {
      final result = await _ocrService.scanFrontSide(context, imageFile);
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(isProcessing: false),
          ),
        );
      }
      return result;
    } catch (e) {
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(
              isProcessing: false,
              errorMessage: "Front scan error: $e",
            ),
          ),
        );
      }
      return NidScanResult(
        success: false,
        errorMessage: "Front scan error: $e",
      );
    }
  }

  /// Complete back side scan
  Future<NidScanResult> scanBackSide(
    BuildContext context,
    File imageFile,
    NidScanResult frontData,
  ) async {
    if (!_isDisposed) {
      _setState(
        (state) => state.copyWith(
          liveOcrState: state.liveOcrState.copyWith(isProcessing: true),
        ),
      );
    }

    try {
      final result = await _ocrService.scanBackSide(
        context,
        imageFile,
        frontData,
      );
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(isProcessing: false),
          ),
        );
      }
      return result;
    } catch (e) {
      if (!_isDisposed) {
        _setState(
          (state) => state.copyWith(
            liveOcrState: state.liveOcrState.copyWith(
              isProcessing: false,
              errorMessage: "Back scan error: $e",
            ),
          ),
        );
      }
      return frontData.copyWith(
        success: false,
        errorMessage: "Back scan error: $e",
      );
    }
  }

  /// Reset state
  void reset() {
    stopAutoOcr();
    if (!_isDisposed) {
      _setState((state) => state.copyWith(liveOcrState: const LiveOcrState()));
    }
  }

  /// Set error message
  void setError(String error) {
    if (!_isDisposed) {
      _setState(
        (state) => state.copyWith(
          liveOcrState: state.liveOcrState.copyWith(errorMessage: error),
        ),
      );
    }
  }

  /// Clear error
  void clearError() {
    if (!_isDisposed) {
      _setState(
        (state) => state.copyWith(
          liveOcrState: state.liveOcrState.copyWith(errorMessage: null),
        ),
      );
    }
  }

  /// Set camera initialized state
  void setCameraInitialized(bool initialized) {
    if (!_isDisposed) {
      _setState((state) => state.copyWith(isCameraInitialized: initialized));
    }
  }

  /// Set camera controller
  void setCameraController(CameraController? controller) {
    if (!_isDisposed) {
      _setState((state) => state.copyWith(cameraController: controller));
    }
  }

  /// Set final scan result
  void setFinalScanResult(NidScanResult? result) {
    if (!_isDisposed) {
      _setState((state) => state.copyWith(finalScanResult: result));
    }
  }
}
