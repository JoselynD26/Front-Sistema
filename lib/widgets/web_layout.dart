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
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);
    
    final backgroundColor = _isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final cardColor = _isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, size: 28),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: _isDarkMode ? "Modo Claro" : "Modo Oscuro",
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: yaviracOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: yaviracOrange.withOpacity(0.3)),
            ),
            child: const Text(
              'YAVIRAC',
              style: TextStyle(
                color: yaviracOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cardColor,
                      ),
                      child: widget.child,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[700] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Desarrolladoras: Joselyn Dicao y María Ortiz | Colaborador: Raul Hidalgo",
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode ? Colors.grey.shade300 : Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: widget.floatingActionButton != null
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: yaviracOrange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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