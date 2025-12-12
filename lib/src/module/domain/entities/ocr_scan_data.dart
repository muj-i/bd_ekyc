import 'dart:io';

/// Data class holding OCR scan results during live scanning
class OcrScanData {
  final String? ocrText;
  final String? extractedNidNumber;
  final String? extractedDateOfBirth;
  final String? extractedName;
  final String? extractedYear;
  final String? issueDate;
  final bool isProcessing;
  final String? errorMessage;
  final File? lastCapturedImage;
  final bool? hasValidBackData;

  const OcrScanData({
    this.ocrText,
    this.extractedNidNumber,
    this.extractedDateOfBirth,
    this.extractedName,
    this.extractedYear,
    this.issueDate,
    this.isProcessing = false,
    this.errorMessage,
    this.lastCapturedImage,
    this.hasValidBackData,
  });

  OcrScanData copyWith({
    String? ocrText,
    String? extractedNidNumber,
    String? extractedDateOfBirth,
    String? extractedName,
    String? extractedYear,
    String? issueDate,
    bool? isProcessing,
    String? errorMessage,
    File? lastCapturedImage,
    bool? hasValidBackData,
  }) {
    return OcrScanData(
      ocrText: ocrText ?? this.ocrText,
      extractedNidNumber: extractedNidNumber ?? this.extractedNidNumber,
      extractedDateOfBirth: extractedDateOfBirth ?? this.extractedDateOfBirth,
      extractedName: extractedName ?? this.extractedName,
      extractedYear: extractedYear ?? this.extractedYear,
      issueDate: issueDate ?? this.issueDate,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
      hasValidBackData: hasValidBackData ?? this.hasValidBackData,
    );
  }

  bool get hasValidNidData =>
      extractedNidNumber != null &&
      extractedDateOfBirth != null &&
      extractedName != null;

  String get displayText {
    if (errorMessage != null) return "Error: $errorMessage";
    if (isProcessing) return "Reading...";
    if (ocrText == null || ocrText!.isEmpty) {
      return "Point NID at the cutout area";
    }

    final isBackSideMode = hasValidBackData != null;

    String result = "";
    if (isBackSideMode) {
      (issueDate != null) ? result += "Issue Date: $issueDate\n" : null;
      result += hasValidBackData == true
          ? "✓ Valid back side detected"
          : "⚠ Scanning back side...";
    } else {
      (extractedNidNumber != null)
          ? result += "NID: $extractedNidNumber\n"
          : null;
      (extractedName != null) ? result += "Name: $extractedName\n" : null;
      (extractedDateOfBirth != null)
          ? result += "DOB: $extractedDateOfBirth\n"
          : null;
    }

    if (result.isEmpty && ocrText != null) {
      result =
          "RAW: ${ocrText!.length > 100 ? '${ocrText!.substring(0, 100)}...' : ocrText}";
    }

    return result.trim();
  }

  @override
  String toString() {
    return 'OcrScanData(nid: $extractedNidNumber, name: $extractedName, dob: $extractedDateOfBirth, processing: $isProcessing)';
  }
}
