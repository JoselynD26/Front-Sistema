import 'package:flutter/material.dart';

enum DialogType { info, success, warning, error }

class CustomDialog extends StatelessWidget {
  final String title;
  final String description;
  final Widget? content; 
  final DialogType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;
  final bool showCancel;
  final bool isLoading;

  const CustomDialog({
    super.key,
    required this.title,
    this.description = "",
    this.content,
    this.type = DialogType.info,
    this.onConfirm,
    this.onCancel,
    this.confirmText = "Aceptar",
    this.cancelText = "Cancelar",
    this.showCancel = false,
    this.isLoading = false,
  });

  List<Color> get _gradientColors {
    switch (type) {
      case DialogType.info: return [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]; // Blue
      case DialogType.success: return [const Color(0xFF059669), const Color(0xFF10B981)]; // Emerald
      case DialogType.warning: return [const Color(0xFFD97706), const Color(0xFFF59E0B)]; // Amber
      case DialogType.error: return [const Color(0xFFDC2626), const Color(0xFFEF4444)]; // Red
    }
  }

  IconData get _icon {
    switch (type) {
      case DialogType.info: return Icons.info_rounded;
      case DialogType.success: return Icons.check_circle_rounded;
      case DialogType.warning: return Icons.warning_rounded;
      case DialogType.error: return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final descColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400), 
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    colors: _gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(_icon, size: 48, color: Colors.white),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (content != null) 
                      content!
                    else 
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: descColor, height: 1.5),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        if (showCancel) ...[
                          Expanded(
                            child: TextButton(
                              onPressed: onCancel ?? () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(cancelText, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(colors: _gradientColors),
                              boxShadow: [
                                BoxShadow(
                                  color: _gradientColors.first.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : (onConfirm ?? () => Navigator.pop(context)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                  )
                                : Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
