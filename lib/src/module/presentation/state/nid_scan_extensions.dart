/// Extensions and builder widgets for NID scan state management
library;

import 'package:bd_ekyc/exports.dart';

/// Extension methods for easy state access
extension NidScanContextExtension on BuildContext {
  /// Get the NidScanController (rebuilds on changes)
  NidScanController get scanController => NidScanProvider.of(this);

  /// Get the current OCR scan data
  OcrScanData get scanData => scanController.scanData;

  /// Get camera initialization state
  bool get isCameraInitialized => scanController.isCameraInitialized;
}

/// Widget that rebuilds when scan state changes
class NidScanBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    OcrScanData scanData,
    NidScanController controller,
  )
  builder;

  const NidScanBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final controller = NidScanProvider.of(context);
    return builder(context, controller.scanData, controller);
  }
}
