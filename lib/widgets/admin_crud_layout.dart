import 'package:flutter/material.dart';
import 'web_layout.dart';
import '../screens/detalle_sede_screen.dart';

class AdminCRUDLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onAdd;
  final String addLabel;
  final Widget? filters;
  final int? idSede;
  final bool scrollable;

  const AdminCRUDLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle = "Gestión de registros",
    this.onAdd,
    this.addLabel = "Nuevo",
    this.filters,
    this.idSede,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      title: title,
      idSede: idSede,
      scrollable: scrollable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),

                    ],
                  ),
                ),
                if (onAdd != null)
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(addLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (filters != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: filters!,
            ),

          // Main Content Card
          // Si es scrollable=false (pantalla completa), usamos Expanded para llenar el espacio
          // Si es scrollable=true (default), dejamos que el contenido determine su altura (dentro del SingleChildScrollView de WebLayout)
          scrollable 
            ? _buildContentCard()
            : Expanded(child: _buildContentCard()),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}
