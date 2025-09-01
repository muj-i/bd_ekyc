import 'package:bd_ekyc/exports.dart';

/// Generic custom state management using InheritedWidget
class CustomStateManager<T> extends InheritedWidget {
  final T state;
  final void Function(T) updateState;

  const CustomStateManager({
    required this.state,
    required this.updateState,
    required super.child,
    super.key,
  });

  static CustomStateManager<T> of<T>(BuildContext context) {
    final CustomStateManager<T>? result = context
        .dependOnInheritedWidgetOfExactType<CustomStateManager<T>>();
    assert(result != null, 'No CustomStateManager<$T> found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(CustomStateManager<T> oldWidget) =>
      state != oldWidget.state;
}

class CustomStateful<T> extends StatefulWidget {
  final T initialState;
  final Widget Function(BuildContext, T, void Function(T)) builder;

  const CustomStateful({
    super.key,
    required this.initialState,
    required this.builder,
  });

  @override
  State<CustomStateful<T>> createState() => _CustomStatefulState<T>();
}

class _CustomStatefulState<T> extends State<CustomStateful<T>> {
  late T _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  void _updateState(T newState) {
    setState(() {
      _state = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomStateManager<T>(
      state: _state,
      updateState: _updateState,
      child: widget.builder(context, _state, _updateState),
    );
  }
}

// Example usage:
// CustomStateful<int>(
//   initialState: 0,
//   builder: (context, count, setCount) => ...,
// )
