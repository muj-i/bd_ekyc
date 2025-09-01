import 'package:bd_ekyc/exports.dart';

/// Helper class to access NID OCR state and controller from anywhere in the widget tree
class NidOcrStateProvider {
  /// Get the current NID OCR state from context
  static NidOcrAppState of(BuildContext context) {
    return CustomStateManager.of<NidOcrAppState>(context).state;
  }

  /// Get the NID OCR controller from context
  static NidOcrController controllerOf(BuildContext context) {
    return of(context).controller;
  }
}
