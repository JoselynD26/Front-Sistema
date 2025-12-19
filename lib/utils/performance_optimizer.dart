import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Optimizador de rendimiento para prevenir rebuilds excesivos
class PerformanceOptimizer {
  static const Duration _debounceDelay = Duration(milliseconds: 100);
  static final Map<String, DateTime> _lastCalls = {};

  /// Debounce para funciones que se llaman frecuentemente
  static bool shouldExecute(String key) {
    final now = DateTime.now();
    final lastCall = _lastCalls[key];
    
    if (lastCall == null || now.difference(lastCall) > _debounceDelay) {
      _lastCalls[key] = now;
      return true;
    }
    return false;
  }

  /// Ejecuta callback en el siguiente frame
  static void scheduleCallback(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
}

/// Widget que previene rebuilds innecesarios
class OptimizedBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final String? debugLabel;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.debugLabel,
  });

  @override
  State<OptimizedBuilder> createState() => _OptimizedBuilderState();
}

class _OptimizedBuilderState extends State<OptimizedBuilder> {
  Widget? _cachedWidget;
  
  @override
  Widget build(BuildContext context) {
    final key = widget.debugLabel ?? 'optimized_builder_${hashCode}';
    
    if (_cachedWidget == null || PerformanceOptimizer.shouldExecute(key)) {
      _cachedWidget = widget.builder(context);
    }
    
    return _cachedWidget!;
  }
}