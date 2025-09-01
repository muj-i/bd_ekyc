class NidValidationResult {
  final bool frontSideValid;
  final bool bothSidesMatch;
  final bool backSideValid;
  final String? errorMessage;

  const NidValidationResult({
    required this.frontSideValid,
    required this.bothSidesMatch,
    required this.backSideValid,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'NidValidationResult(frontSideValid: $frontSideValid, bothSidesMatch: $bothSidesMatch, backSideValid: $backSideValid, errorMessage: $errorMessage)';
  }
}
