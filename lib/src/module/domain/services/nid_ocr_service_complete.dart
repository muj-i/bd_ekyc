import 'package:bd_ekyc/exports.dart';

/// Complete NID OCR Service with ALL business logic extracted from original KycServices
/// This contains the complete, working flow from the original KYC module
class NidOcrServiceComplete {
  late final TextRecognizer _textRecognizer;
  late final BarcodeScanner _barcodeScanner;

  NidOcrServiceComplete() {
    _textRecognizer = TextRecognizer();
    _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.pdf417]);
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }

  /// Scan text from image using ML Kit (exact copy from KycServices)
  Future<String> _scanTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final scannedText = recognizedText.text;

      debugLog("Scanned NID text data: \n\n$scannedText\n\n");
      return scannedText;
    } catch (e) {
      debugLog("Text recognition error: $e");
      return "";
    }
  }

  /// Public method for external scanning (for live OCR)
  Future<String> scanTextFromImage(File imageFile) async {
    return await _scanTextFromImage(imageFile);
  }

  /// Scan front side of NID (exact copy from original KycServices)
  Future<NidScanResult> scanFrontSide(
    BuildContext context,
    File imageFile,
  ) async {
    final contextNotMounted = 'Context is not mounted';
    final couldNotReadNidData =
        "Could not read NID data from front side. Please select a clear picture.";
    final errorScanningFrontSide = 'Error scanning front side';

    try {
      final scannedData = await _scanTextFromImage(imageFile);

      if (!context.mounted) {
        return NidScanResult(success: false, errorMessage: contextNotMounted);
      }

      // Extract data from front side
      final (nidNumber, is13DigitNid) = await _extractNidNumber(
        context,
        scannedData,
      );
      final nidDateOfBirth =
          _extractDateOfBirthFromFront(context, scannedData) ?? "";
      final nidName = _extractEnglishNameFromNID(context, scannedData) ?? "";
      final isSmartNid = _isSmartNidDetected(scannedData);

      debugLog("NID Data - Number: $nidNumber");
      debugLog("NID Data - Name: $nidName");
      debugLog("NID Data - DOB: $nidDateOfBirth");
      debugLog("NID Data - IsSmartNID: $isSmartNid");

      // Validate extracted data
      if (nidNumber != null &&
          nidNumber.isNotEmpty &&
          nidDateOfBirth.isNotEmpty &&
          nidName.isNotEmpty) {
        return NidScanResult(
          success: true,
          nidNumber: nidNumber,
          is13DigitNid: is13DigitNid,
          nidName: nidName,
          nidDateOfBirth: nidDateOfBirth,
          isSmartNid: isSmartNid,
          imageFile: imageFile,
        );
      } else {
        debugLog(
          "Front scan failed - NID: $nidNumber, DOB: $nidDateOfBirth, Name: $nidName",
        );

        return NidScanResult(success: false, errorMessage: couldNotReadNidData);
      }
    } catch (e) {
      debugLog("Front side scan error: $e");
      final errorMessage = "$errorScanningFrontSide: $e";
      return NidScanResult(success: false, errorMessage: errorMessage);
    }
  }

  /// Process OCR text for live scanning (back side specific)
  OcrScanData processOcrTextForBackSide(
    String scannedText,
    NidScanResult frontData,
  ) {
    if (scannedText.isEmpty) {
      return const OcrScanData(ocrText: "", errorMessage: "No text detected");
    }

    // For back side, extract back-side specific data
    final nidIssueDate = extractIssueDateFromBack(scannedText);
    final hasValidBackData = _isValidBackSideData(
      scannedText,
      frontData,
      nidIssueDate,
    );

    // For back side, show back-side specific extracted data
    return OcrScanData(
      ocrText: scannedText,
      extractedNidNumber: null, // Don't show front data for back scan
      extractedDateOfBirth: null,
      issueDate: nidIssueDate,
      extractedName: null, // Don't show front data for back scan
      extractedYear: _extractBirthYearFromScannedData(scannedText),
      isProcessing: false,
      hasValidBackData: hasValidBackData,
    );
  }

  /// Check if scanned text contains valid back side data
  bool _isValidBackSideData(
    String scannedText,
    NidScanResult frontData,
    String? issueDate,
  ) {
    debugLog(
      "Checking back side validity for scanned text: ${scannedText.length > 100 ? '${scannedText.substring(0, 100)}...' : scannedText}",
    );

    if (frontData.isSmartNid == true) {
      // For smart NID: check if NID number appears and has valid issue date
      final cleanBackData = scannedText
          .replaceAll("<", "")
          .replaceAll(" ", "")
          .replaceAll("-", "");
      final cleanNidNumber = (frontData.nidNumber ?? "")
          .replaceAll(" ", "")
          .replaceAll("-", "");

      // Try multiple matching approaches like in the main validation
      bool numberMatches = false;

      // Approach 1: Direct match
      if (cleanBackData.contains(cleanNidNumber)) {
        numberMatches = true;
      }

      // Approach 2: Try partial match (at least 8 consecutive digits)
      if (!numberMatches && cleanNidNumber.length >= 8) {
        final partialNid = cleanNidNumber.substring(0, 8);
        if (cleanBackData.contains(partialNid)) {
          numberMatches = true;
        }
      }

      final hasIssueDate = issueDate != null && issueDate.isNotEmpty;
      final issueDateValid =
          hasIssueDate && issueDate.trim() != frontData.nidDateOfBirth?.trim();

      debugLog(
        "Smart NID back check - Number matches: $numberMatches, Has issue date: $hasIssueDate, Date valid: $issueDateValid",
      );
      debugLog("Front NID Number: ${frontData.nidNumber}");
      debugLog("Front DOB: ${frontData.nidDateOfBirth}");
      debugLog("Back Issue Date: $issueDate");

      return numberMatches && hasIssueDate && issueDateValid;
    } else {
      // For old NID: should NOT have issue date, check for typical back side indicators
      final hasNoIssueDate = issueDate == null || issueDate.isEmpty;

      // Look for typical old NID back side patterns (address, signature area, etc.)
      final hasBackSideIndicators = _hasOldNidBackSideIndicators(scannedText);

      debugLog(
        "Old NID back check - No issue date: $hasNoIssueDate, Has back indicators: $hasBackSideIndicators",
      );
      debugLog("Detected issue date: '$issueDate'");

      return hasNoIssueDate && hasBackSideIndicators;
    }
  }

  /// Check for typical old NID back side indicators
  bool _hasOldNidBackSideIndicators(String scannedText) {
    final backSideKeywords = [
      // English keywords
      'address',
      'village',
      'post',
      'thana',
      'district',
      'signature',
      'date',
      'issue',
      'valid',
      'authority',
      'chairman',
      'blood',
      'group',
      'father',
      'mother',
      'spouse',
      'permanent',
      'present',
      // Bengali keywords
      'ঠিকানা',
      'গ্রাম',
      'পোস্ট',
      'থানা',
      'জেলা',
      'স্বাক্ষর',
      'পিতা',
      'মাতা',
      'স্থায়ী',
      'বর্তমান',
      'রক্তের',
      'গ্রুপ',
    ];

    final lowercaseText = scannedText.toLowerCase();
    final foundKeywords = backSideKeywords
        .where((keyword) => lowercaseText.contains(keyword.toLowerCase()))
        .toList();

    debugLog("Found back side keywords: $foundKeywords");
    return foundKeywords.length >= 2; // At least 2 back-side indicators
  }

  /// Process OCR text for live scanning
  OcrScanData processOcrText(String scannedText) {
    if (scannedText.isEmpty) {
      return const OcrScanData(ocrText: "", errorMessage: "No text detected");
    }

    // Use the complete extraction logic
    final (nidNumber, _) = extractNidNumberSync(scannedText);
    final extractedDateOfBirth = extractDateOfBirthFromFront(scannedText);
    final extractedName = extractEnglishNameFromNID(scannedText);
    final extractedYear = _extractBirthYearFromScannedData(scannedText);

    return OcrScanData(
      ocrText: scannedText,
      extractedNidNumber: nidNumber,
      extractedDateOfBirth: extractedDateOfBirth,
      extractedName: extractedName,
      extractedYear: extractedYear,
      isProcessing: false,
    );
  }

  /// Synchronous version for live OCR
  (String?, bool) extractNidNumberSync(String scannedData) {
    // Try smart NID pattern first
    final smartNIDPattern = RegExp(r'\d{3} \d{3} \d{4}');
    final matches = smartNIDPattern.allMatches(scannedData);

    if (matches.isNotEmpty) {
      final nidNum = matches.first.group(0)?.replaceAll(" ", "");
      return (nidNum, false);
    }

    // Try old NID pattern
    final regExp = RegExp(r'ID NO: (\d+)');
    final match = regExp.firstMatch(scannedData);
    final nidNum = match?.group(1) ?? "";

    if (nidNum.isNotEmpty) {
      switch (nidNum.length) {
        case 10:
        case 17:
          return (nidNum, false);
        case 13:
          final birthYear = _extractBirthYearFromScannedData(scannedData);
          if (birthYear.isNotEmpty) {
            final convertedNid = birthYear + nidNum;
            return (convertedNid, true);
          }
          return (null, false);
        default:
          return (null, false);
      }
    }

    return (null, false);
  }

  /// Extract date of birth from front side (exact logic from original KycServices)
  String? extractDateOfBirthFromFront(String scannedData) {
    String? dateOfBirth = "";
    final smartNIDPattern = RegExp(r'\d{2} [A-Za-z]+ \d{4}');
    final matches = smartNIDPattern.allMatches(scannedData);

    if (matches.isNotEmpty) {
      try {
        dateOfBirth = matches.first.group(0);
        debugLog("dateOfBirthFromFirstAttempt :: $dateOfBirth");

        if (dateOfBirth!.contains("Noy")) {
          final datePattern = RegExp(r'\d{2} [a-zA-Z]{3} \d{4}');
          final secondMatches = datePattern.allMatches(scannedData);

          if (secondMatches.isNotEmpty) {
            try {
              dateOfBirth = secondMatches.last.group(0)!;
              debugLog("dateOfBirthFromSecondAttempt :: $dateOfBirth");
            } catch (e) {
              debugLog("dateOfBirthException :: $e");
            }
          } else {
            dateOfBirth = "";
          }
        }
      } catch (e) {
        debugLog("dateOfBirthException :: $e");
      }
    } else {
      dateOfBirth = "";
    }

    return dateOfBirth;
  }

  /// Extract issue date from back side (exact logic from original KycServices)
  String? extractIssueDateFromBack(String scannedData) {
    final datePattern = RegExp(r'\d{2} [A-Za-z]+ \d{4}');
    final matches = datePattern.allMatches(scannedData);
    if (matches.isNotEmpty) {
      return matches.first.group(0) ?? "";
    } else {
      return null;
    }
  }

  /// Extract English name with comprehensive logic (exact logic from original KycServices)
  String? extractEnglishNameFromNID(String scannedText) {
    try {
      final lines = scannedText.split('\n').map((e) => e.trim()).toList();

      // 1. Search up to 7 lines after "Name"
      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].toLowerCase().startsWith('name')) {
          for (int j = 1; j <= 7 && (i + j) < lines.length; j++) {
            final possibleName = lines[i + j].trim();

            // Valid name: uppercase, letters/spaces/dot/dash
            if (RegExp(r"^[A-Z .\'\-]{3,}$").hasMatch(possibleName)) {
              debugLog(
                "Name found after 'Name:' (within 7 lines): $possibleName",
              );
              return possibleName;
            }
          }
        }
      }

      // 2. Fallback inline regex
      final fallbackPattern = RegExp(
        r"Name\s*[:\-]?\s*([A-Za-z.'\- ]{3,})",
        caseSensitive: false,
      );
      final match = fallbackPattern.firstMatch(scannedText);
      if (match != null) {
        final name = match.group(1)?.trim();
        debugLog("Name found from fallback regex: $name");
        return name;
      }

      // 3. Try to find name after ID NO if nothing else works
      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].toLowerCase().contains('id no')) {
          for (int j = i + 1; j < lines.length; j++) {
            final possibleName = lines[j].trim();
            if (RegExp(r"^[A-Z .\'\-]{3,}$").hasMatch(possibleName)) {
              debugLog("Name found after 'ID NO': $possibleName");
              return possibleName;
            }
          }
        }
      }
    } catch (e) {
      debugLog("extractEnglishNameFromNID error: $e");
    }

    return "";
  }

  /// Extract 4-digit birth year from scanned data (exact logic from original KycServices)
  String _extractBirthYearFromScannedData(String scannedData) {
    // Try to extract year from date patterns like "DD MMM YYYY" or "DD/MM/YYYY"
    // Look for patterns with actual date context, not just standalone years
    final dateWithYearPattern = RegExp(
      r'\b\d{1,2}[\s\-\/]([a-zA-Z]{3}|[a-zA-Z]+)[\s\-\/]((19|20)\d{2})\b',
    );
    final dateMatches = dateWithYearPattern.allMatches(scannedData);

    if (dateMatches.isNotEmpty) {
      final yearFromDate = dateMatches.first.group(2);
      debugLog("Found birth year from date context: $yearFromDate");
      if (yearFromDate != null) {
        return yearFromDate;
      }
    }

    // Fallback: look for standalone years, but prefer older years (birth years are typically older)
    final yearPattern = RegExp(r'\b(19|20)\d{2}\b');
    final matches = yearPattern.allMatches(scannedData);
    debugLog(
      "Found birth year matches: ${matches.map((m) => m.group(0)).toList()}",
    );

    if (matches.isNotEmpty) {
      // Prefer years from 1930-2010 (reasonable birth year range)
      for (final match in matches) {
        final year = match.group(0);
        if (year != null) {
          final yearInt = int.tryParse(year);
          if (yearInt != null && yearInt >= 1930 && yearInt <= 2010) {
            debugLog("Selected birth year: $year");
            return year;
          }
        }
      }
      // If no reasonable birth year found, return the first one
      return matches.first.group(0) ?? "";
    }

    return "";
  }

  /// Check if NID is smart NID (exact logic from original KycServices)
  bool _isSmartNidDetected(String scannedData) {
    final smartNIDPattern = RegExp(r'\d{3} \d{3} \d{4}');
    return smartNIDPattern.hasMatch(scannedData);
  }

  /// Extract NID number (exact copy from original KycServices)
  Future<(String?, bool)> _extractNidNumber(
    BuildContext context,
    String scannedData,
  ) async {
    // Try smart NID pattern first
    final smartNIDPattern = RegExp(r'\d{3} \d{3} \d{4}');
    final matches = smartNIDPattern.allMatches(scannedData);

    if (matches.isNotEmpty) {
      final nidNum = matches.first.group(0)?.replaceAll(" ", "");
      showWarningToast(
        context,
        sec: 2,
        message:
            "Smart NID pattern found. Switching to Smart NID scanning mode...",
      );
      return (nidNum, false);
    } else {
      return await _extractOldNIDNumber(context, scannedData);
    }
  }

  /// Extract old NID number (exact copy from original KycServices)
  Future<(String?, bool)> _extractOldNIDNumber(
    BuildContext context,
    String scannedData,
  ) async {
    final regExp = RegExp(r'ID NO: (\d+)');
    final match = regExp.firstMatch(scannedData);
    final nidNum = match?.group(1) ?? "";

    if (nidNum.isNotEmpty) {
      switch (nidNum.length) {
        case 10:
          showWarningToast(
            context,
            sec: 2,
            message: "10 digit NID found, switching to 10 digit NID pattern.",
          );
          return (nidNum, false);
        case 13:
          // For 13-digit NID, we need to convert it to 17-digit by adding birth year
          final birthYear = _extractBirthYearFromScannedData(scannedData);
          if (birthYear.isNotEmpty) {
            final convertedNid = birthYear + nidNum;
            showWarningToast(
              context,
              sec: 2,
              message:
                  "13 digit NID found, 4 digit birth year added to create 17 digit NID.",
            );
            return (convertedNid, true);
          } else {
            return (null, false);
          }
        case 17:
          showWarningToast(
            context,
            sec: 2,
            message: "17 digit NID found, switching to 17 digit NID pattern.",
          );
          return (nidNum, false);
        default:
          return (null, false);
      }
    }

    return (nidNum, false);
  }

  /// Extract date of birth from front side (exact copy from original KycServices)
  String? _extractDateOfBirthFromFront(
    BuildContext context,
    String scannedData,
  ) {
    debugLog("=== DATE EXTRACTION DEBUG ===");
    debugLog("Input scanned data: $scannedData");

    String? dateOfBirth = "";
    final smartNIDPattern = RegExp(r'\d{2} [A-Za-z]+ \d{4}');
    final matches = smartNIDPattern.allMatches(scannedData);

    debugLog("Smart NID date pattern matches found: ${matches.length}");
    for (final match in matches) {
      debugLog("Date match: ${match.group(0)}");
    }

    if (matches.isNotEmpty) {
      try {
        dateOfBirth = matches.first.group(0);
        debugLog("dateOfBirthFromFirstAttempt :: $dateOfBirth");

        if (dateOfBirth!.contains("Noy")) {
          debugLog("Date contains 'Noy', trying secondary pattern");
          final datePattern = RegExp(r'\d{2} [a-zA-Z]{3} \d{4}');
          final secondMatches = datePattern.allMatches(scannedData);

          debugLog("Secondary pattern matches: ${secondMatches.length}");
          if (secondMatches.isNotEmpty) {
            try {
              dateOfBirth = secondMatches.last.group(0)!;
              debugLog("dateOfBirthFromSecondAttempt :: $dateOfBirth");
            } catch (e) {
              debugLog("dateOfBirthException :: $e");
            }
          } else {
            dateOfBirth = "";
          }
        }
      } catch (e) {
        debugLog("dateOfBirthException :: $e");
      }
    } else {
      dateOfBirth = "";
      debugLog("No date patterns found in text");
    }

    debugLog("Final extracted date of birth: $dateOfBirth");
    debugLog("=== END DATE EXTRACTION DEBUG ===");
    return dateOfBirth;
  }

  /// Extract issue date from back side (exact copy from original KycServices)
  String? _extractIssueDateFromBack(BuildContext context, String scannedData) {
    final datePattern = RegExp(r'\d{2} [A-Za-z]+ \d{4}');
    final matches = datePattern.allMatches(scannedData);
    if (matches.isNotEmpty) {
      return matches.first.group(0) ?? "";
    } else {
      return "";
    }
  }

  /// Extract English name from NID text (exact copy from original KycServices)
  String? _extractEnglishNameFromNID(BuildContext context, String scannedText) {
    try {
      final lines = scannedText.split('\n').map((e) => e.trim()).toList();

      // 1. Search up to 7 lines after "Name"
      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].toLowerCase().startsWith('name')) {
          for (int j = 1; j <= 7 && (i + j) < lines.length; j++) {
            final possibleName = lines[i + j].trim();

            // Valid name: uppercase, letters/spaces/dot/dash
            if (RegExp(r"^[A-Z .\'\-]{3,}$").hasMatch(possibleName)) {
              debugLog(
                "Name found after 'Name:' (within 7 lines): $possibleName",
              );
              return possibleName;
            }
          }
        }
      }

      // 2. Fallback inline regex
      final fallbackPattern = RegExp(
        r"Name\s*[:\-]?\s*([A-Za-z.'\- ]{3,})",
        caseSensitive: false,
      );
      final match = fallbackPattern.firstMatch(scannedText);
      if (match != null) {
        final name = match.group(1)?.trim();
        debugLog("Name found from fallback regex: $name");
        return name;
      }

      // 3. Try to find name after ID NO if nothing else works
      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].toLowerCase().contains('id no')) {
          for (int j = i + 1; j < lines.length; j++) {
            final possibleName = lines[j].trim();
            if (RegExp(r"^[A-Z .\'\-]{3,}$").hasMatch(possibleName)) {
              debugLog("Name found after 'ID NO': $possibleName");
              return possibleName;
            }
          }
        }
      }
    } catch (e) {
      debugLog("extractEnglishNameFromNID error: $e");
    }

    return "";
  }

  /// Scan back side of NID (exact copy from original KycServices)
  Future<NidScanResult> scanBackSide(
    BuildContext context,
    File imageFile,
    NidScanResult frontData,
  ) async {
    final contextNotMounted = 'Context is not mounted';
    final nidFrontAndBackSideDoNotMatch =
        "NID front and back sides do not match or back side data is invalid.";
    final errorScanningBackSide = 'Error scanning back side';

    try {
      final scannedBackData = await _scanTextFromImage(imageFile);

      if (!context.mounted) {
        return frontData.copyWith(
          success: false,
          errorMessage: contextNotMounted,
        );
      }

      final nidIssueDate =
          _extractIssueDateFromBack(context, scannedBackData) ?? "";

      debugLog("\n${"=" * 60}");
      debugLog("📋 NID BACK SIDE SCAN INITIATED");
      debugLog("=" * 60);
      debugLog(
        "NID Type: ${frontData.isSmartNid == true ? '🆕 SMART NID' : '📄 OLD NID'}",
      );
      debugLog("Front NID Number: ${frontData.nidNumber}");
      debugLog("Front DOB: ${frontData.nidDateOfBirth}");
      debugLog("Extracted Issue Date (OCR): $nidIssueDate");
      debugLog("=" * 60 + "\n");

      // Use new PDF417-based validation
      final validation = await _validateNidSidesWithPdf417(
        context,
        imageFile: imageFile,
        frontData: frontData,
        backData: scannedBackData,
        issueDate: nidIssueDate,
      );

      debugLog("\n${"-" * 60}");
      debugLog("📊 VALIDATION RESULT");
      debugLog("-" * 60);
      debugLog("Back Side Valid: ${validation.backSideValid}");
      debugLog("Both Sides Match: ${validation.bothSidesMatch}");
      debugLog("Error (if any): ${validation.errorMessage ?? 'None'}");
      debugLog("-" * 60 + "\n");

      if (validation.backSideValid && validation.bothSidesMatch) {
        return frontData.copyWith(
          success: true,
          nidIssueDate: nidIssueDate,
          backSideImageFile: imageFile,
        );
      } else {
        debugLog(
          "Validation failed - BackValid: ${validation.backSideValid}, BothMatch: ${validation.bothSidesMatch}",
        );
        debugLog("Validation error: ${validation.errorMessage}");
        return frontData.copyWith(
          success: false,
          errorMessage:
              validation.errorMessage ?? nidFrontAndBackSideDoNotMatch,
          backSideImageFile:
              imageFile, // Keep the image even if validation fails
        );
      }
    } catch (e) {
      debugLog("Back side scan error: $e");
      final errorMessage = "$errorScanningBackSide: $e";

      return frontData.copyWith(
        success: false,
        errorMessage: errorMessage,
        backSideImageFile: imageFile, // Keep the image even on error
      );
    }
  }

  /// Validate NID front and back sides using PDF417 barcode
  /// This new version reads PDF417 barcode and matches NID/DOB from front side
  Future<NidValidationResult> _validateNidSidesWithPdf417(
    BuildContext context, {
    required File imageFile,
    required NidScanResult frontData,
    required String backData,
    required String issueDate,
  }) async {
    if (frontData.isSmartNid == true) {
      return await _validateSmartNidBackSideNew(
        imageFile,
        frontNidNumber: frontData.nidNumber ?? "",
        frontDateOfBirth: frontData.nidDateOfBirth ?? "",
      );
    } else {
      return await _validateOldNidBackSideNew(
        imageFile,
        frontNidNumber: frontData.nidNumber ?? "",
        frontDateOfBirth: frontData.nidDateOfBirth ?? "",
      );
    }
  }

  // ============================================================================
  // OLD VALIDATION FUNCTIONS (COMMENTED OUT - KEPT FOR REFERENCE)
  // ============================================================================

  /*
  /// OLD: Validate NID front and back sides (exact copy from original KycServices)
  NidValidationResult _validateNidSides(
    BuildContext context, {
    required NidScanResult frontData,
    required String backData,
    required String issueDate,
  }) {
    if (frontData.isSmartNid == true) {
      return _validateSmartNidBackSide(
        context,
        nidNumber: frontData.nidNumber ?? "",
        nidDateOfBirth: frontData.nidDateOfBirth ?? "",
        backData: backData,
        issueDate: issueDate,
      );
    } else {
      return _validateOldNidBackSide(context, issueDate);
    }
  }

  /// OLD: Validate smart NID back side (exact copy from original KycServices)
  NidValidationResult _validateSmartNidBackSide(
    BuildContext context, {
    required String nidNumber,
    required String nidDateOfBirth,
    required String backData,
    required String issueDate,
  }) {
    final issueDateNotFound = 'Issue date not found on back side';
    final nidNumberNotFound = 'NID number not found on back side';
    final issueDateMatchDob = 'Issue date matches date of birth';

    debugLog("=== SMART NID BACK SIDE VALIDATION ===");
    debugLog("Front NID Number: $nidNumber");
    debugLog("Front DOB: $nidDateOfBirth");
    debugLog("Back Issue Date: $issueDate");
    debugLog("Back Data Length: ${backData.length}");

    if (issueDate.isEmpty) {
      debugLog("VALIDATION FAILED: Issue date is empty");
      return NidValidationResult(
        frontSideValid: true,
        backSideValid: false,
        bothSidesMatch: false,
        errorMessage: issueDateNotFound,
      );
    }

    // Check if NID number appears in back side data with multiple approaches
    final cleanBackData = backData
        .replaceAll("<", "")
        .replaceAll(" ", "")
        .replaceAll("-", "");
    final cleanNidNumber = nidNumber.replaceAll(" ", "").replaceAll("-", "");

    // Try different matching approaches
    bool numberMatches = false;

    // Approach 1: Direct match
    if (cleanBackData.contains(cleanNidNumber)) {
      numberMatches = true;
      debugLog("NID number found: Direct match");
    }

    // Approach 2: Try with spaces in different positions
    if (!numberMatches && nidNumber.length >= 10) {
      final nidWithSpaces =
          "${nidNumber.substring(0, 3)} ${nidNumber.substring(3, 6)} ${nidNumber.substring(6)}";
      if (backData.contains(nidWithSpaces)) {
        numberMatches = true;
        debugLog("NID number found: With spaces pattern");
      }
    }

    // Approach 3: Try partial match (at least 8 consecutive digits)
    if (!numberMatches && cleanNidNumber.length >= 8) {
      final partialNid = cleanNidNumber.substring(0, 8);
      if (cleanBackData.contains(partialNid)) {
        numberMatches = true;
        debugLog("NID number found: Partial match (8 digits)");
      }
    }

    debugLog("Number matches: $numberMatches");

    // Issue date should be different from date of birth
    final issueDateValid = issueDate.trim() != nidDateOfBirth.trim();
    debugLog("Issue date valid (different from DOB): $issueDateValid");

    final result = NidValidationResult(
      frontSideValid: true,
      backSideValid: true,
      bothSidesMatch: numberMatches && issueDateValid,
      errorMessage: !numberMatches
          ? nidNumberNotFound
          : !issueDateValid
          ? issueDateMatchDob
          : null,
    );

    debugLog("FINAL VALIDATION RESULT: ${result.bothSidesMatch}");
    debugLog("=== END VALIDATION ===");

    return result;
  }

  /// OLD: Validate old NID back side (exact copy from original KycServices)
  NidValidationResult _validateOldNidBackSide(
    BuildContext context,
    String issueDate,
  ) {
    // Store localized string at the beginning
    final oldNidShouldNotHaveIssueDate =
        "Old NID should not have issue date on back side";

    // For old NIDs, back side should NOT have issue date (or it should be empty)
    if (issueDate.isNotEmpty) {
      return NidValidationResult(
        frontSideValid: true,
        backSideValid: false,
        bothSidesMatch: false,
        errorMessage: oldNidShouldNotHaveIssueDate,
      );
    }

    return const NidValidationResult(
      frontSideValid: true,
      backSideValid: true,
      bothSidesMatch: true,
    );
  }
  */

  // ============================================================================
  // PDF417 BARCODE READING FUNCTIONS
  // ============================================================================

  /// Comprehensive reusable PDF417 barcode reader from image file.
  /// Returns a record containing the raw barcode data, extracted NID, and extracted DOB.
  /// Returns null values if no PDF417 barcode is found or parsing fails.
  Future<({String? rawData, String? nidNumber, String? dateOfBirth})>
  readPdf417FromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      debugLog("PDF417 scan found ${barcodes.length} barcodes");

      for (final barcode in barcodes) {
        if (barcode.format == BarcodeFormat.pdf417) {
          final rawData = barcode.rawValue ?? "";
          debugLog("PDF417 raw data: $rawData");

          // Parse NID and DOB from the barcode data
          final nidNumber = _extractNidFromPdf417(rawData);
          final dateOfBirth = _extractDobFromPdf417(rawData);

          debugLog("PDF417 extracted NID: $nidNumber");
          debugLog("PDF417 extracted DOB: $dateOfBirth");

          return (
            rawData: rawData,
            nidNumber: nidNumber,
            dateOfBirth: dateOfBirth,
          );
        }
      }

      debugLog("No PDF417 barcode found in image");
      return (rawData: null, nidNumber: null, dateOfBirth: null);
    } catch (e) {
      debugLog("PDF417 reading error: $e");
      return (rawData: null, nidNumber: null, dateOfBirth: null);
    }
  }

  /// Extract NID number from PDF417 raw data.
  /// BD NID barcodes typically contain 10, 13, or 17 digit NID numbers.
  String? _extractNidFromPdf417(String rawData) {
    if (rawData.isEmpty) return null;

    // Clean the data - remove common separators and whitespace
    final cleanData = rawData.replaceAll(RegExp(r'[\s\-<>]'), '');

    // Try to find 17 digit NID (most common in smart cards)
    final nid17Pattern = RegExp(r'\d{17}');
    final nid17Match = nid17Pattern.firstMatch(cleanData);
    if (nid17Match != null) {
      return nid17Match.group(0);
    }

    // Try to find 10 digit NID
    final nid10Pattern = RegExp(r'\d{10}');
    final nid10Match = nid10Pattern.firstMatch(cleanData);
    if (nid10Match != null) {
      return nid10Match.group(0);
    }

    // Try to find 13 digit NID
    final nid13Pattern = RegExp(r'\d{13}');
    final nid13Match = nid13Pattern.firstMatch(cleanData);
    if (nid13Match != null) {
      return nid13Match.group(0);
    }

    return null;
  }

  /// Extract Date of Birth from PDF417 raw data.
  /// BD NID barcodes may contain DOB in various formats.
  String? _extractDobFromPdf417(String rawData) {
    if (rawData.isEmpty) return null;

    // Try pattern: DD MMM YYYY (e.g., "15 Jan 1990")
    final dobPattern1 = RegExp(r'\d{2}\s+[A-Za-z]{3,}\s+\d{4}');
    final match1 = dobPattern1.firstMatch(rawData);
    if (match1 != null) {
      return match1.group(0);
    }

    // Try pattern: DD/MM/YYYY or DD-MM-YYYY
    final dobPattern2 = RegExp(r'\d{2}[\/\-]\d{2}[\/\-]\d{4}');
    final match2 = dobPattern2.firstMatch(rawData);
    if (match2 != null) {
      return match2.group(0);
    }

    // Try pattern: YYYYMMDD (compact format)
    final dobPattern3 = RegExp(r'(19|20)\d{6}');
    final match3 = dobPattern3.firstMatch(rawData);
    if (match3 != null) {
      final compact = match3.group(0)!;
      // Convert YYYYMMDD to DD MMM YYYY
      final year = compact.substring(0, 4);
      final month = compact.substring(4, 6);
      final day = compact.substring(6, 8);
      return "$day/$month/$year";
    }

    return null;
  }

  /// Validate Old NID back side using PDF417 barcode data.
  /// Matches NID and DOB from front side with barcode data.
  Future<NidValidationResult> _validateOldNidBackSideNew(
    File backImageFile, {
    required String frontNidNumber,
    required String frontDateOfBirth,
  }) async {
    debugLog("\n${"#" * 60}");
    debugLog("📄 OLD NID BACK SIDE VALIDATION (PDF417 BARCODE)");
    debugLog("#" * 60);
    debugLog("");
    debugLog("📌 FRONT SIDE DATA:");
    debugLog("   NID Number: $frontNidNumber");
    debugLog("   Date of Birth: $frontDateOfBirth");
    debugLog("");

    // Read PDF417 barcode from back side image
    final barcodeData = await readPdf417FromImage(backImageFile);

    debugLog("📷 PDF417 BARCODE SCAN RESULT:");
    if (barcodeData.rawData != null) {
      debugLog("   ✅ Barcode Found!");
      debugLog("   Raw Data: ${barcodeData.rawData}");
      debugLog("   Extracted NID: ${barcodeData.nidNumber ?? 'Not found'}");
      debugLog("   Extracted DOB: ${barcodeData.dateOfBirth ?? 'Not found'}");
    } else {
      debugLog("   ❌ No PDF417 barcode found on back side");
      debugLog("#" * 60 + "\n");
      return const NidValidationResult(
        frontSideValid: true,
        backSideValid: false,
        bothSidesMatch: false,
        errorMessage: "No PDF417 barcode found on back side of NID",
      );
    }
    debugLog("");

    // Match NID number
    final nidMatches = _matchNidNumbers(frontNidNumber, barcodeData.nidNumber);
    debugLog("🔍 MATCHING RESULTS:");
    debugLog("   NID Match: ${nidMatches ? '✅ YES' : '❌ NO'}");
    debugLog("      Front: $frontNidNumber");
    debugLog("      Barcode: ${barcodeData.nidNumber ?? 'N/A'}");

    // Match Date of Birth
    final dobMatches = _matchDates(frontDateOfBirth, barcodeData.dateOfBirth);
    debugLog("   DOB Match: ${dobMatches ? '✅ YES' : '❌ NO'}");
    debugLog("      Front: $frontDateOfBirth");
    debugLog("      Barcode: ${barcodeData.dateOfBirth ?? 'N/A'}");
    debugLog("");

    final bothMatch = nidMatches && dobMatches;

    debugLog(
      "🎯 FINAL RESULT: ${bothMatch ? '✅ VALIDATION PASSED' : '❌ VALIDATION FAILED'}",
    );
    debugLog("#" * 60 + "\n");

    return NidValidationResult(
      frontSideValid: true,
      backSideValid: true,
      bothSidesMatch: bothMatch,
      errorMessage: !bothMatch
          ? "Old NID front and back side data do not match"
          : null,
    );
  }

  /// Validate Smart NID back side using PDF417 barcode data.
  /// Matches NID and DOB from front side with barcode data.
  Future<NidValidationResult> _validateSmartNidBackSideNew(
    File backImageFile, {
    required String frontNidNumber,
    required String frontDateOfBirth,
  }) async {
    debugLog("\n${"#" * 60}");
    debugLog("🆕 SMART NID BACK SIDE VALIDATION (PDF417 BARCODE)");
    debugLog("#" * 60);
    debugLog("");
    debugLog("📌 FRONT SIDE DATA:");
    debugLog("   NID Number: $frontNidNumber");
    debugLog("   Date of Birth: $frontDateOfBirth");
    debugLog("");

    // Read PDF417 barcode from back side image
    final barcodeData = await readPdf417FromImage(backImageFile);

    debugLog("📷 PDF417 BARCODE SCAN RESULT:");
    if (barcodeData.rawData != null) {
      debugLog("   ✅ Barcode Found!");
      debugLog("   Raw Data: ${barcodeData.rawData}");
      debugLog("   Extracted NID: ${barcodeData.nidNumber ?? 'Not found'}");
      debugLog("   Extracted DOB: ${barcodeData.dateOfBirth ?? 'Not found'}");
    } else {
      debugLog("   ❌ No PDF417 barcode found on back side");
      debugLog("#" * 60 + "\n");
      return const NidValidationResult(
        frontSideValid: true,
        backSideValid: false,
        bothSidesMatch: false,
        errorMessage: "No PDF417 barcode found on back side of Smart NID",
      );
    }
    debugLog("");

    // Match NID number
    final nidMatches = _matchNidNumbers(frontNidNumber, barcodeData.nidNumber);
    debugLog("🔍 MATCHING RESULTS:");
    debugLog("   NID Match: ${nidMatches ? '✅ YES' : '❌ NO'}");
    debugLog("      Front: $frontNidNumber");
    debugLog("      Barcode: ${barcodeData.nidNumber ?? 'N/A'}");

    // Match Date of Birth
    final dobMatches = _matchDates(frontDateOfBirth, barcodeData.dateOfBirth);
    debugLog("   DOB Match: ${dobMatches ? '✅ YES' : '❌ NO'}");
    debugLog("      Front: $frontDateOfBirth");
    debugLog("      Barcode: ${barcodeData.dateOfBirth ?? 'N/A'}");
    debugLog("");

    final bothMatch = nidMatches && dobMatches;

    debugLog(
      "🎯 FINAL RESULT: ${bothMatch ? '✅ VALIDATION PASSED' : '❌ VALIDATION FAILED'}",
    );
    debugLog("#" * 60 + "\n");

    return NidValidationResult(
      frontSideValid: true,
      backSideValid: true,
      bothSidesMatch: bothMatch,
      errorMessage: !bothMatch
          ? "Smart NID front and back side data do not match"
          : null,
    );
  }

  /// Helper: Match two NID numbers with flexible comparison.
  /// Handles different formats (with/without spaces, dashes).
  bool _matchNidNumbers(String? frontNid, String? barcodeNid) {
    if (frontNid == null || frontNid.isEmpty) return false;
    if (barcodeNid == null || barcodeNid.isEmpty) return false;

    // Clean both NID numbers
    final cleanFront = frontNid.replaceAll(RegExp(r'[\s\-]'), '');
    final cleanBarcode = barcodeNid.replaceAll(RegExp(r'[\s\-]'), '');

    // Direct match
    if (cleanFront == cleanBarcode) return true;

    // Partial match (one contains the other)
    if (cleanFront.contains(cleanBarcode) ||
        cleanBarcode.contains(cleanFront)) {
      return true;
    }

    // Match at least 8 consecutive digits
    if (cleanFront.length >= 8 && cleanBarcode.length >= 8) {
      final frontPart = cleanFront.substring(0, 8);
      final barcodePart = cleanBarcode.substring(0, 8);
      if (frontPart == barcodePart) return true;
    }

    return false;
  }

  /// Helper: Match two dates with flexible comparison.
  /// Handles different date formats (DD MMM YYYY, DD/MM/YYYY, etc.).
  bool _matchDates(String? frontDob, String? barcodeDob) {
    if (frontDob == null || frontDob.isEmpty) return false;
    if (barcodeDob == null || barcodeDob.isEmpty) return false;

    // Normalize dates for comparison
    final normalizedFront = _normalizeDate(frontDob);
    final normalizedBarcode = _normalizeDate(barcodeDob);

    if (normalizedFront == null || normalizedBarcode == null) {
      // If normalization fails, try direct comparison
      return frontDob.trim().toLowerCase() == barcodeDob.trim().toLowerCase();
    }

    return normalizedFront == normalizedBarcode;
  }

  /// Normalize date string to YYYYMMDD format for comparison.
  String? _normalizeDate(String date) {
    try {
      // Handle DD MMM YYYY format
      final pattern1 = RegExp(r'(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})');
      final match1 = pattern1.firstMatch(date);
      if (match1 != null) {
        final day = match1.group(1)!.padLeft(2, '0');
        final monthStr = match1.group(2)!.toLowerCase();
        final year = match1.group(3)!;
        final month = _monthToNumber(monthStr);
        if (month != null) {
          return "$year$month$day";
        }
      }

      // Handle DD/MM/YYYY or DD-MM-YYYY format
      final pattern2 = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})');
      final match2 = pattern2.firstMatch(date);
      if (match2 != null) {
        final day = match2.group(1)!.padLeft(2, '0');
        final month = match2.group(2)!.padLeft(2, '0');
        final year = match2.group(3)!;
        return "$year$month$day";
      }

      // Handle YYYYMMDD format
      final pattern3 = RegExp(r'^(19|20)\d{6}$');
      if (pattern3.hasMatch(date.replaceAll(RegExp(r'\s'), ''))) {
        return date.replaceAll(RegExp(r'\s'), '');
      }

      return null;
    } catch (e) {
      debugLog("Date normalization error: $e");
      return null;
    }
  }

  /// Convert month name to 2-digit number.
  String? _monthToNumber(String month) {
    const months = {
      'jan': '01',
      'january': '01',
      'feb': '02',
      'february': '02',
      'mar': '03',
      'march': '03',
      'apr': '04',
      'april': '04',
      'may': '05',
      'jun': '06',
      'june': '06',
      'jul': '07',
      'july': '07',
      'aug': '08',
      'august': '08',
      'sep': '09',
      'september': '09',
      'oct': '10',
      'october': '10',
      'nov': '11',
      'november': '11',
      'dec': '12',
      'december': '12',
    };
    return months[month.toLowerCase()];
  }
}
