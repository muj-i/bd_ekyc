import 'dart:ui' as ui;

import 'package:bd_ekyc/exports.dart';

/// Controller for NID scanning - combines state and business logic
class NidScanController extends ChangeNotifier {
  final NidOcrServiceComplete _ocrService;
  Timer? _autoOcrTimer;
  bool _isProcessing = false;
  bool _isDisposed = false;

  // State properties
  OcrScanData _scanData = const OcrScanData();
  bool _isCameraInitialized = false;
  CameraController? _cameraController;
  NidScanResult? _finalScanResult;

  NidScanController() : _ocrService = NidOcrServiceComplete();

  // Getters
  OcrScanData get scanData => _scanData;
  bool get isCameraInitialized => _isCameraInitialized;
  CameraController? get cameraController => _cameraController;
  NidScanResult? get finalScanResult => _finalScanResult;

  @override
  void dispose() {
    _isDisposed = true;
    stopAutoOcr();
    _ocrService.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Set camera initialized state
  void setCameraInitialized(bool initialized) {
    _isCameraInitialized = initialized;
    _notify();
  }

  /// Set camera controller
  void setCameraController(CameraController? controller) {
    _cameraController = controller;
    _notify();
  }

  /// Set final scan result
  void setFinalScanResult(NidScanResult? result) {
    _finalScanResult = result;
    _notify();
  }

  /// Start auto OCR processing with timer
  void startAutoOcr(CameraController controller) {
    if (_isDisposed) return;
    stopAutoOcr();

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

  /// Start auto OCR processing for back side with timer
  void startAutoOcrForBackSide(
    CameraController controller,
    NidScanResult frontData,
  ) {
    if (_isDisposed) return;
    stopAutoOcr();

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

  /// Stop auto OCR processing
  void stopAutoOcr() {
    _autoOcrTimer?.cancel();
    _autoOcrTimer = null;
  }

  /// Process OCR from camera
  Future<void> _processOcr(CameraController controller) async {
    if (_isDisposed || _isProcessing) return;

    _isProcessing = true;
    _scanData = _scanData.copyWith(isProcessing: true);
    _notify();

    try {
      final XFile file = await controller.takePicture();
      final scannedText = await _ocrService.scanTextFromImage(File(file.path));

      if (_isDisposed) return;

      final ocrState = _ocrService.processOcrText(scannedText);

      _scanData = ocrState.copyWith(
        isProcessing: false,
        lastCapturedImage: File(file.path),
      );
      _notify();

      if (!_isDisposed && _scanData.hasValidNidData) {
        stopAutoOcr();
        debugLog("✅ Valid NID data found - stopping auto-OCR");
        debugLog("NID: ${_scanData.extractedNidNumber}");
        debugLog("Name: ${_scanData.extractedName}");
        debugLog("DOB: ${_scanData.extractedDateOfBirth}");
      }

      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await File(file.path).delete();
        } catch (e) {
          debugLog("Error deleting temp file: $e");
        }
      });
    } catch (e) {
      if (!_isDisposed) {
        _scanData = _scanData.copyWith(
          isProcessing: false,
          errorMessage: "OCR Error: $e",
        );
        _notify();
      }
      debugLog("OCR Error: $e");
    }

    _isProcessing = false;
  }

  /// Process OCR from camera for back side
  Future<void> _processOcrForBackSide(
    CameraController controller,
    NidScanResult frontData,
  ) async {
    if (_isDisposed || _isProcessing) return;

    _isProcessing = true;
    _scanData = _scanData.copyWith(isProcessing: true);
    _notify();

    try {
      final XFile file = await controller.takePicture();
      final scannedText = await _ocrService.scanTextFromImage(File(file.path));

      if (_isDisposed) return;

      final ocrState = _ocrService.processOcrTextForBackSide(
        scannedText,
        frontData,
      );

      _scanData = ocrState.copyWith(
        isProcessing: false,
        lastCapturedImage: File(file.path),
      );
      _notify();

      if (!_isDisposed && ocrState.hasValidBackData == true) {
        stopAutoOcr();
        debugLog("✅ Valid back side data found - stopping auto-OCR");
        debugLog(
          "Issue Date: ${_ocrService.extractIssueDateFromBack(scannedText)}",
        );
        debugLog("Front NID: ${frontData.nidNumber}");
        debugLog("Smart NID: ${frontData.isSmartNid}");
      }

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
        _scanData = _scanData.copyWith(
          isProcessing: false,
          errorMessage: "Failed to process image: $e",
        );
        _notify();
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Manual capture and crop from camera cutout
  /// Returns both cropped file and original file path for barcode scanning
  Future<({File? croppedFile, File? originalFile})> captureAndCropWithOriginal({
    required CameraController controller,
    required double cutoutWidth,
    required double cutoutHeight,
    required double screenWidth,
    required double screenHeight,
  }) async {
    debugLog("Starting captureAndCropWithOriginal process");

    try {
      final XFile file = await controller.takePicture();
      debugLog("Picture taken successfully: ${file.path}");

      final imageFile = File(file.path);

      // Save a copy of original for barcode scanning
      final directory = await getTemporaryDirectory();
      final originalCopyPath =
          '${directory.path}/original_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final originalCopy = await imageFile.copy(originalCopyPath);
      debugLog("Original image copied for barcode: $originalCopyPath");

      final croppedFile = await _cropImageToCutout(
        imageFile,
        cutoutWidth,
        cutoutHeight,
        screenWidth,
        screenHeight,
        controller,
      );

      try {
        await imageFile.delete();
      } catch (e) {
        debugLog("Error deleting original image: $e");
      }

      debugLog(
        "Returning cropped: ${croppedFile?.path}, original: ${originalCopy.path}",
      );
      return (croppedFile: croppedFile, originalFile: originalCopy);
    } catch (e) {
      debugLog("Capture error: $e");
      if (!_isDisposed) {
        _scanData = _scanData.copyWith(errorMessage: "Capture Error: $e");
        _notify();
      }
      return (croppedFile: null, originalFile: null);
    }
  }

  /// Manual capture and crop from camera cutout (legacy - for front side)
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

      final imageFile = File(file.path);
      final croppedFile = await _cropImageToCutout(
        imageFile,
        cutoutWidth,
        cutoutHeight,
        screenWidth,
        screenHeight,
        controller,
      );

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
        _scanData = _scanData.copyWith(errorMessage: "Capture Error: $e");
        _notify();
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
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      debugLog("Original image size: ${image.width} x ${image.height}");
      debugLog("Screen size: $screenWidth x $screenHeight");
      debugLog("Cutout size: $cutoutWidth x $cutoutHeight");

      final double imageAspectRatio = image.width / image.height;
      final double screenAspectRatio = screenWidth / screenHeight;

      double scaleX, scaleY;
      double offsetX = 0, offsetY = 0;

      if (imageAspectRatio > screenAspectRatio) {
        scaleY = image.height / screenHeight;
        scaleX = scaleY;
        offsetX = (image.width - screenWidth * scaleX) / 2;
      } else {
        scaleX = image.width / screenWidth;
        scaleY = scaleX;
        offsetY = (image.height - screenHeight * scaleY) / 2;
      }

      final double cutoutCenterX = screenWidth / 2;
      final double cutoutCenterY = screenHeight / 2;

      final double imageCutoutCenterX = offsetX + cutoutCenterX * scaleX;
      final double imageCutoutCenterY = offsetY + cutoutCenterY * scaleY;

      final double cropWidth = cutoutWidth * scaleX;
      final double cropHeight = cutoutHeight * scaleY;
      final double cropLeft = imageCutoutCenterX - cropWidth / 2;
      final double cropTop = imageCutoutCenterY - cropHeight / 2;

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
        "Crop rectangle: (${adjustedCropLeft.toInt()}, ${adjustedCropTop.toInt()}) "
        "${adjustedCropWidth.toInt()} x ${adjustedCropHeight.toInt()}",
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

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

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        adjustedCropWidth.toInt(),
        adjustedCropHeight.toInt(),
      );

      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final croppedBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final croppedFile = File(
        '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(croppedBytes);

      debugLog("Cropped image saved: ${croppedFile.path}");
      debugLog(
        "Cropped image size: ${adjustedCropWidth.toInt()} x ${adjustedCropHeight.toInt()}",
      );

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
    _scanData = _scanData.copyWith(isProcessing: true);
    _notify();

    try {
      final result = await _ocrService.scanFrontSide(context, imageFile);
      _scanData = _scanData.copyWith(isProcessing: false);
      _notify();
      return result;
    } catch (e) {
      _scanData = _scanData.copyWith(
        isProcessing: false,
        errorMessage: "Front scan error: $e",
      );
      _notify();
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
    NidScanResult frontData, {
    File? originalImageFile, // Original full image for barcode scanning
  }) async {
    _scanData = _scanData.copyWith(isProcessing: true);
    _notify();

    try {
      final result = await _ocrService.scanBackSide(
        context,
        imageFile,
        frontData,
        originalImageFile: originalImageFile,
      );
      _scanData = _scanData.copyWith(isProcessing: false);
      _notify();
      return result;
    } catch (e) {
      _scanData = _scanData.copyWith(
        isProcessing: false,
        errorMessage: "Back scan error: $e",
      );
      _notify();
      return frontData.copyWith(
        success: false,
        errorMessage: "Back scan error: $e",
      );
    }
  }

  /// Reset state
  void reset() {
    stopAutoOcr();
    _scanData = const OcrScanData();
    _notify();
  }

  /// Set error message
  void setError(String error) {
    _scanData = _scanData.copyWith(errorMessage: error);
    _notify();
  }

  /// Clear error
  void clearError() {
    _scanData = _scanData.copyWith(errorMessage: null);
    _notify();
  }
}
