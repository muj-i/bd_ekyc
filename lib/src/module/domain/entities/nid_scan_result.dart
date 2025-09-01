import 'dart:io';

class NidScanResult {
  final bool success;
  final String? nidNumber;
  final String? nidName;
  final String? nidDateOfBirth;
  final String? nidIssueDate;
  final bool? is13DigitNid;
  final bool? isSmartNid;
  final File? imageFile; // For backward compatibility
  final File? frontSideImageFile;
  final File? backSideImageFile;
  final String? errorMessage;

  const NidScanResult({
    required this.success,
    this.nidNumber,
    this.nidName,
    this.nidDateOfBirth,
    this.nidIssueDate,
    this.is13DigitNid,
    this.isSmartNid,
    this.imageFile,
    this.frontSideImageFile,
    this.backSideImageFile,
    this.errorMessage,
  });

  NidScanResult copyWith({
    bool? success,
    String? nidNumber,
    String? nidName,
    String? nidDateOfBirth,
    String? nidIssueDate,
    bool? is13DigitNid,
    bool? isSmartNid,
    File? imageFile,
    File? frontSideImageFile,
    File? backSideImageFile,
    String? errorMessage,
  }) {
    return NidScanResult(
      success: success ?? this.success,
      nidNumber: nidNumber ?? this.nidNumber,
      nidName: nidName ?? this.nidName,
      nidDateOfBirth: nidDateOfBirth ?? this.nidDateOfBirth,
      nidIssueDate: nidIssueDate ?? this.nidIssueDate,
      is13DigitNid: is13DigitNid ?? this.is13DigitNid,
      isSmartNid: isSmartNid ?? this.isSmartNid,
      imageFile: imageFile ?? this.imageFile,
      frontSideImageFile: frontSideImageFile ?? this.frontSideImageFile,
      backSideImageFile: backSideImageFile ?? this.backSideImageFile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'NidScanResult(success: $success, nidNumber: $nidNumber, nidName: $nidName, nidDateOfBirth: $nidDateOfBirth, nidIssueDate: $nidIssueDate, is13DigitNid: $is13DigitNid, isSmartNid: $isSmartNid, errorMessage: $errorMessage)';
  }
}
