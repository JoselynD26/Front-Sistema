import 'package:flutter/material.dart';

/// Widget para prevenir problemas con mouse_tracker
class MouseTrackerFix extends StatelessWidget {
  final Widget child;
  
  const MouseTrackerFix({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      onHover: (_) {},
      child: child,
    );
  }
}

/// Mixin para controlar setState de manera segura
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (_mounted && mounted) {
      setState(fn);
    }
  }
}