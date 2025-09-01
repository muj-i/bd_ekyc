/// Migration utility to help convert Provider-based widgets to custom state management
///
/// This file provides utilities to make the migration from Provider to custom state
/// management as smooth as possible while preserving all business logic.
library;

import 'package:bd_ekyc/exports.dart';

/// Extension methods to make migration easier
extension NidOcrContextExtension on BuildContext {
  /// Get the current live OCR state (replaces context.read\<LiveOcrNotifier\>().state)
  LiveOcrState get liveOcrState => NidOcrStateProvider.of(this).liveOcrState;

  /// Get the OCR controller (replaces context.read\<LiveOcrNotifier\>())
  NidOcrController get ocrController => NidOcrStateProvider.controllerOf(this);

  /// Get camera initialization state
  bool get isCameraInitialized =>
      NidOcrStateProvider.of(this).isCameraInitialized;

  /// Get the full NID OCR app state
  NidOcrAppState get nidOcrState => NidOcrStateProvider.of(this);
}

/// Widget that watches for state changes (replaces Consumer\<LiveOcrNotifier\>)
class LiveOcrStateBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    LiveOcrState state,
    NidOcrController controller,
  )
  builder;

  const LiveOcrStateBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final appState = NidOcrStateProvider.of(context);
    return builder(context, appState.liveOcrState, appState.controller);
  }
}

/// Widget that only rebuilds when specific parts of the state change
class SelectiveLiveOcrStateBuilder<T> extends StatelessWidget {
  final T Function(LiveOcrState state) selector;
  final Widget Function(
    BuildContext context,
    T value,
    NidOcrController controller,
  )
  builder;

  const SelectiveLiveOcrStateBuilder({
    super.key,
    required this.selector,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final appState = NidOcrStateProvider.of(context);
    final selectedValue = selector(appState.liveOcrState);
    return builder(context, selectedValue, appState.controller);
  }
}
