import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/mouse_tracker_fix.dart';

class WebLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const WebLayout({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  _WebLayoutState createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> with SafeStateMixin {
  bool _isDarkMode = false;

  void _toggleTheme() {
    safeSetState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _logout() async {
    // Aquí puedes agregar la lógica de logout si tienes ApiService disponible
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildWebLayout(BuildContext context) {
    return MouseTrackerFix(
      child: _buildWebLayoutContent(context),
    );
  }

  Widget _buildWebLayoutContent(BuildContext context) {
    final backgroundColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        titleSpacing: 24,
        toolbarHeight: 70,
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_rounded,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              widget.title,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: textColor.withOpacity(0.7),
            ),
            tooltip: _isDarkMode ? "Modo Claro" : "Modo Oscuro",
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 24),
            child: IconButton(
              onPressed: _logout,
              icon: Icon(Icons.logout_rounded, color: Colors.red[400]),
              tooltip: "Cerrar Sesión",
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.child,
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      "Desarrollado por Joselyn Dicao, María Ortiz y Raul Hidalgo",
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: widget.floatingActionButton != null
          ? Container(
              margin: const EdgeInsets.only(bottom: 16, right: 16),
              child: widget.floatingActionButton,
            )
          : null,
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return MouseTrackerFix(
      child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.child,
      floatingActionButton: widget.floatingActionButton,
      backgroundColor: widget.backgroundColor,
      ),
    );
  }
}