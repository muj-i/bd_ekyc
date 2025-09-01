import 'dart:io';

class LiveOcrState {
  final String? ocrText;
  final String? extractedNidNumber;
  final String? extractedDateOfBirth;
  final String? extractedName;
  final String? extractedYear;
  final String? issueDate;
  final bool isProcessing;
  final String? errorMessage;
  final File? lastCapturedImage;
  final bool? hasValidBackData; // New field for back side validation

  const LiveOcrState({
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

  LiveOcrState copyWith({
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
    return LiveOcrState(
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

    // Check if this is back side scanning mode
    final isBackSideMode = hasValidBackData != null;

    String result = "";
    if (isBackSideMode) {
      // For back side, show different information
      (issueDate != null) ? result += "Issue Date: $issueDate\n" : null;
      result += hasValidBackData == true
          ? "✓ Valid back side detected"
          : "⚠ Scanning back side...";
    } else {
      // For front side, show normal information
      (extractedNidNumber != null) ? result += "NID: $extractedNidNumber\n" : null;
      (extractedName != null) ? result += "Name: $extractedName\n" : null;
      (extractedDateOfBirth != null) ? result += "DOB: $extractedDateOfBirth\n" : null;
    }

    if (result.isEmpty && ocrText != null) {
      result =
          "RAW: ${ocrText!.length > 100 ? '${ocrText!.substring(0, 100)}...' : ocrText}";
    }

    return result.trim();
  }

  @override
  String toString() {
    return 'LiveOcrState(extractedNidNumber: $extractedNidNumber, extractedName: $extractedName, extractedDateOfBirth: $extractedDateOfBirth, isProcessing: $isProcessing, errorMessage: $errorMessage)';
  }
}
