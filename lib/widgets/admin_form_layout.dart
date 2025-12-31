import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/mouse_tracker_fix.dart';

class AdminFormLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final List<Widget>? actions;
  final Color primaryColor;
  final bool isLoading;

  const AdminFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.actions,
    this.primaryColor = const Color(0xFF6366F1), // Indigo 500
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseTrackerFix(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Elegant Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.05),
                    Colors.white,
                    primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Back Button (Added for consistency)
            Positioned(
              top: 24,
              left: 24,
              child: SafeArea(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Volver",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Section
                            _buildHeader(context),
                            
                            // Form Content
                            Padding(
                              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...children,
                                  if (actions != null) ...[
                                    const SizedBox(height: 40),
                                    ...actions!,
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            if (isLoading)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Hero(
            tag: 'form_icon_${title}',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
        ],
      ),
    );
  }
}

// Custom Premium Input Decoration helpers
InputDecoration premiumInputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  required Color primaryColor,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Icon(icon, color: primaryColor),
    ),
    labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
    hintStyle: TextStyle(color: Colors.grey.shade400),
    floatingLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade100),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    filled: true,
    fillColor: Colors.grey.shade50.withOpacity(0.5),
  );
}
