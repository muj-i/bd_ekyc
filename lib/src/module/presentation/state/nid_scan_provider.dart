import 'package:bd_ekyc/exports.dart';
import 'package:bd_ekyc/src/module/presentation/widgets/edge_to_edge_config.dart';

/// InheritedNotifier wrapper that provides NidScanController to the widget tree
class NidScanProvider extends InheritedNotifier<NidScanController> {
  const NidScanProvider({
    super.key,
    required NidScanController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Get the NidScanController from context (rebuilds on changes)
  static NidScanController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<NidScanProvider>();
    assert(provider != null, 'No NidScanProvider found in context');
    return provider!.notifier!;
  }

  /// Get the NidScanController without subscribing to changes
  static NidScanController read(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<NidScanProvider>();
    assert(provider != null, 'No NidScanProvider found in context');
    return provider!.notifier!;
  }
}

/// Entry point widget that creates and manages the NidScanController lifecycle
class NidScanManager extends StatefulWidget {
  final Widget child;

  const NidScanManager({super.key, required this.child});

  @override
  State<NidScanManager> createState() => _NidScanManagerState();
}

class _NidScanManagerState extends State<NidScanManager> {
  late final NidScanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NidScanController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EdgeToEdgeConfig(
      builder: (isEdgeToEdge, os) =>
          NidScanProvider(controller: _controller, child: widget.child),
    );
  }
}
