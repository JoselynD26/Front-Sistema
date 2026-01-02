import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/conflict_dialog.dart';
import '../widgets/custom_dialog.dart';

class AdminReservasScreen extends StatefulWidget {
  final int? idSede;
  const AdminReservasScreen({super.key, this.idSede});

  @override
  _AdminReservasScreenState createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  
  late TabController _tabController;
  
  List<dynamic> _pendientes = [];
  List<dynamic> _historial = [];
  
  bool _cargandoPendientes = true;
  bool _cargandoHistorial = true;
  String _historialError = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarPendientes();
    _cargarHistorial();
  }

  // --- HELPERS PARA VALIDACIÓN ---
  int _parseHora(String h) {
    if (h == null || h.isEmpty) return 0;
    try {
      final parts = h.split(":");
      final val = int.parse(parts[0]) * 100 + int.parse(parts[1]);
      return val;
    } catch (_) {
      return 0;
    }
  }

  String _normalize(String s) {
    return s.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Lunes";
      case 2: return "Martes";
      case 3: return "Miércoles";
      case 4: return "Jueves";
      case 5: return "Viernes";
      case 6: return "Sábado";
      case 7: return "Domingo";
      default: return "";
    }
  }
  // -------------------------------
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPendientes() async {
    try {
      final data = await _apiService.obtenerReservasPendientes();
      print("[DEBUG RESERVAS] Pendientes RAW: $data");
      
      if (mounted) {
        setState(() {
          _pendientes = data;
          _cargandoPendientes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoPendientes = false);
      debugPrint("Error loading pending: $e");
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() {
       _cargandoHistorial = true; 
       _historialError = "";
    });
    try {
      // Usamos el nuevo endpoint que trae TODO el historial (incluyendo rechazadas/canceladas)
      List<dynamic> data = await _apiService.listarHistorialReservas();
      
      // Filtrar por sede basándonos en si el docente pertenece a esta sede (Match por Nombre porque el endpoint no devuelve ID)
      if (widget.idSede != null) {
        try {
           final docentesSede = await _apiService.listarDocentesPorSede(widget.idSede!);
           
           // Construimos los nombres completos como vienen en el historial: "NOMBRES APELLIDOS"
           final nombresValidos = docentesSede.map((d) {
             final n = (d['nombres'] ?? '').toString().trim();
             final a = (d['apellidos'] ?? '').toString().trim();
             return "$n $a".toUpperCase();
           }).toSet();
           
           data = data.where((r) {
             final dNombre = (r['docente_nombre'] ?? '').toString().trim().toUpperCase();
             return nombresValidos.contains(dNombre);
           }).toList();
        } catch (e) {
           debugPrint("Error filtrando historial por nombre: $e");
        }
      }

      if (mounted) {
        setState(() {
          // Filtramos para NO mostrar pendientes en historial (ya están en la otra pestaña)
          _historial = data.where((r) => (r['estado'] ?? '').toString().toLowerCase() != 'pendiente').toList();
          
          // Ordenar por fecha desc (más reciente primero)
          _historial.sort((a, b) {
             final fA = a['fecha'] ?? "";
             final fB = b['fecha'] ?? "";
             return fB.compareTo(fA); // Descendente
          });
          
          _cargandoHistorial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoHistorial = false;
          _historialError = "Error: $e";
        });
      }
      debugPrint("Error loading history: $e");
    }
  }

  void _showPremiumSnackBar(String message, {Color color = const Color(0xFF1E3A8A), IconData icon = Icons.info_outline_rounded}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      )
    );
  }

  Future<void> _aprobarReserva(Map<String, dynamic> r) async {
    final reservaId = r['id'];
    
    // 1. VALIDACIÓN DE CONFLICTOS Y AUTO-CANCELACIÓN
    // Si la reserva pide liberación (indicado en motivo) o si simplemente colisiona,
    // debemos liberar el aula anterior del docente.
    
    debugPrint("=== STARTING APPROVAL FOR RESERVA ID: $reservaId ===");
    debugPrint("FULL RESERVA OBJECT: $r");
    debugPrint("AVAILABLE KEYS: ${r.keys.toList()}");
    
    try {
      dynamic docenteId = r['docente_id'] ?? r['id_docente'];
      
      // Fallback: Si no hay ID, buscar por nombre
      if (docenteId == null && r['docente_nombre'] != null && widget.idSede != null) {
          debugPrint("⚠️ Docente ID missing. Attempting lookup by name: ${r['docente_nombre']}");
          try {
             final docentes = await _apiService.listarDocentesPorSede(widget.idSede!);
             final nombreBuscado = r['docente_nombre'].toString().trim().toUpperCase();
             
             final docenteEncontrado = docentes.firstWhere((d) {
                final n = (d['nombres'] ?? '').toString().trim();
                final a = (d['apellidos'] ?? '').toString().trim();
                final nombreCompleto = "$n $a".toUpperCase(); // Formato usual: Nombres Apellidos
                final nombreInverso = "$a $n".toUpperCase(); // Por si acaso: Apellidos Nombres
                
                return nombreCompleto == nombreBuscado || nombreInverso == nombreBuscado;
             }, orElse: () => null);

             if (docenteEncontrado != null) {
                docenteId = docenteEncontrado['id'];
                debugPrint("✅ Docente ID found via lookup: $docenteId");
             } else {
                debugPrint("❌ Could not find docente by name: $nombreBuscado");
             }
          } catch (e) {
             debugPrint("Error looking up docente by name: $e");
          }
      }

      debugPrint("Final Docente ID to use: $docenteId");
      
      if (docenteId != null) {
         debugPrint("Fetching schedules for docente $docenteId...");
         final horariosDocente = await _apiService.obtenerHorarioDocente(docenteId);
         debugPrint("Schedules fetched: ${horariosDocente is List ? horariosDocente.length : 'NOT A LIST'}");

         if (horariosDocente is List) {
            String fechaStr = r['fecha'];
            String hInicioStr = r['hora_inicio'] ?? "00:00";
            String hFinStr = r['hora_fin'] ?? "00:00";

            // Si viene en formato 'hora', parsear rango si es posible
            if (r['hora'] != null && (r['hora_inicio'] == null) && r['hora'].toString().contains("-")) {
                try {
                  final parts = r['hora'].toString().split("-");
                  if (parts.length == 2) {
                     hInicioStr = parts[0].trim();
                     hFinStr = parts[1].trim();
                     debugPrint("Parsed times from string: $hInicioStr to $hFinStr");
                  }
                } catch (e) {
                   debugPrint("Error parsing hora string: $e");
                }
            }

            final date = DateTime.parse(fechaStr);
            final diaSemana = _getDayName(date.weekday);
            final inicioNuevo = _parseHora(hInicioStr);
            final finNuevo = _parseHora(hFinStr);

            // Buscar conflicto
            debugPrint("ADMIN CHECK: Validando conflicto para Docente ID: $docenteId en $diaSemana ($inicioNuevo - $finNuevo)");
            
            if (horariosDocente.isEmpty) {
               // Debug messages removed for production or can use premium snippet if needed
            }


            final claseConflictiva = horariosDocente.firstWhere((h) {
              final hDia = h['dia']?.toString() ?? "";
              
              final start = _parseHora(h['hora_inicio']);
              final end = _parseHora(h['hora_fin']);
              
              debugPrint("   -> Revisando clase: $hDia ($start - $end) vs $diaSemana ($inicioNuevo - $finNuevo)");
              
              if (_normalize(hDia) != _normalize(diaSemana)) {
                 return false;
              }
              
              final seSolapan = (inicioNuevo < end && finNuevo > start);
              if (seSolapan) debugPrint("      [MATCH] Conflict detected!");
              return seSolapan;
            }, orElse: () => null);

            if (claseConflictiva != null) {
              // EXISTE CONFLICTO -> Preguntar al ADMIN antes de proceder
              final aulaAnterior = claseConflictiva['aula_nombre'] ?? "su aula actual";
              final horarioAnterior = "${claseConflictiva['hora_inicio']} - ${claseConflictiva['hora_fin']}";
              
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => ConflictDialog(
                  aulaNombre: aulaAnterior,
                  horario: horarioAnterior,
                  dia: diaSemana,
                  docenteNombre: r['docente_nombre'] ?? "Docente",
                  onCancel: () => Navigator.pop(ctx, false),
                  onLiberar: () => Navigator.pop(ctx, true),
                )
              );

              if (confirm != true) return; // Cancelar acción si dice que no

              debugPrint("ADMIN: Cancelando clase anterior conflictiva ID: ${claseConflictiva['id']}");
              await _apiService.crearHorarioCancelado(
                 claseConflictiva['id'], 
                 fechaStr, 
                 "Cancelado por Aprobación de Reserva (Admin)",
                 sedeId: widget.idSede
              );
              _showPremiumSnackBar("Clase anterior liberada automáticamente", color: Colors.indigo, icon: Icons.playlist_add_check_circle_rounded);
            }
         }
      }
    } catch (e) {
      debugPrint("Error validando conflictos en aprobación: $e");
    }

    final success = await _apiService.aprobarReserva(reservaId);
    if (success) {
      _cargarPendientes();
      _cargarHistorial(); // Refrescar historial para verla aprobada
      _cargarHistorial(); // Refrescar historial para verla aprobada
      showDialog(
        context: context,
        builder: (_) => CustomDialog(
          title: "¡Reserva Aprobada!",
          description: "La reserva ha sido aprobada y agendada correctamente.",
          type: DialogType.success,
          onConfirm: () => Navigator.pop(context),
          confirmText: "Aceptar",
        )
      );
    } else {
      _showPremiumSnackBar("Error al aprobar la reserva", color: Colors.red, icon: Icons.error_outline_rounded);
    }
  }

  Future<void> _rechazarReserva(int reservaId) async {
    final success = await _apiService.rechazarReserva(reservaId);
    if (success) {
      _cargarPendientes();
      _cargarHistorial();
      _cargarHistorial();
      showDialog(
        context: context,
        builder: (_) => CustomDialog(
          title: "Reserva Rechazada",
          description: "La solicitud ha sido rechazada.",
          type: DialogType.info, // Or warning/success based on preference, Info seems neutral/safe
          onConfirm: () => Navigator.pop(context),
          confirmText: "Aceptar",
        )
      );
    } else {
      _showPremiumSnackBar("Error al rechazar la reserva", color: Colors.red, icon: Icons.error_outline_rounded);
    }
  }
  
  Future<void> _eliminarReserva(int reservaId) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (dialogContext) => CustomDialog(
        title: "Confirmar eliminación",
        description: "¿Estás seguro de eliminar este registro del historial? Esta acción no se puede deshacer.",
        type: DialogType.warning,
        confirmText: "Eliminar",
        cancelText: "Cancelar",
        showCancel: true,
      )
    );
    
    if (confirm == true && mounted) {
       // Show loading
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (loadingContext) => const CustomDialog(
           title: "Eliminando...",
           description: "Por favor espera",
           type: DialogType.info,
           isLoading: true,
         ),
       );

       final success = await _apiService.eliminarReserva(reservaId).catchError((_) => false);
       
       if (mounted) {
         Navigator.pop(context); // Close loading (using stable context)

         if (success) {
           _cargarHistorial();
           showDialog(
             context: context,
             builder: (successContext) => CustomDialog(
               title: "¡Éxito!",
               description: "Registro eliminado correctamente.",
               type: DialogType.success,
               onConfirm: () => Navigator.pop(successContext),
               confirmText: "Aceptar",
             )
           );
         } else {
           showDialog(
             context: context,
             builder: (errorContext) => const CustomDialog(
               title: "Error",
               description: "No se pudo eliminar el registro.",
               type: DialogType.error,
               confirmText: "Aceptar",
             )
           );
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Gestión de Reservas",
      subtitle: "Administración y seguimiento de espacios",
      idSede: widget.idSede,
      scrollable: false, // Importante para TabView
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: "PENDIENTES", icon: Icon(Icons.access_time_filled_rounded)),
                Tab(text: "HISTORIAL", icon: Icon(Icons.history_rounded)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PENDIENTES
                _buildPendientesList(),
                // TAB 2: HISTORIAL
                _buildHistorialList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPendientesList() {
    if (_cargandoPendientes) return const Center(child: CircularProgressIndicator());
    if (_pendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text("No hay solicitudes pendientes", style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _pendientes.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final r = _pendientes[index];
        return _ReservaCard(
          reserva: r, 
          isHistory: false,
          onAprove: () {
            debugPrint("BUTTON CLICKED: Aprobar reserva ${r['id']}");
            _aprobarReserva(r);
          },
          onReject: () => _rechazarReserva(r['id']),
        );
      },
    );
  }

  Widget _buildHistorialList() {
    if (_cargandoHistorial) return const Center(child: CircularProgressIndicator());
    if (_historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text("No hay historial de reservas", style: TextStyle(color: Colors.grey)),
             if (_historialError.isNotEmpty) 
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text(_historialError, style: const TextStyle(color: Colors.red, fontSize: 12)),
               ),
          ],
        )
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _historial.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final r = _historial[index];
        return _ReservaCard(
          reserva: r, 
          isHistory: true,
          onDelete: () => _eliminarReserva(r['id'] ?? r['reserva_id']), // Support both keys just in case
        );
      },
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final Map<String, dynamic> reserva;
  final bool isHistory;
  final VoidCallback? onAprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  const _ReservaCard({required this.reserva, required this.isHistory, this.onAprove, this.onReject, this.onDelete});

  @override
  Widget build(BuildContext context) {
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine status style
    String estado = (reserva['estado'] ?? 'pendiente').toString().toLowerCase();
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time;
    String statusText = "PENDIENTE";

    if (estado == 'aprobada') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = "APROBADA";
    } else if (estado == 'rechazada') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = "RECHAZADA";
    } else if (estado == 'cancelada') {
      statusColor = Colors.grey;
      statusIcon = Icons.highlight_off;
      statusText = "CANCELADA";
    }
    
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final primaryText = isDark ? Colors.white : yaviracBlue;
    final subText = isDark ? Colors.grey.shade400 : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: yaviracOrange.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.meeting_room_rounded, color: yaviracOrange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Aula: ${reserva["aula_nombre"] ?? 'Sin Aula'}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Profesor: ${reserva["docente_nombre"] ?? 'Desconocido'}",
                      style: TextStyle(fontSize: 14, color: subText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(statusIcon, size: 14, color: statusColor),
                     const SizedBox(width: 4),
                     Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                   ]
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoBadge(icon: Icons.calendar_today, text: reserva["fecha"] ?? "N/A"),
              _InfoBadge(icon: Icons.access_time, text: reserva["hora"] ?? "${reserva['hora_inicio']} - ${reserva['hora_fin']}"),
            ],
          ),
          if (reserva['motivo'] != null && reserva['motivo'].toString().isNotEmpty) ...[
             const SizedBox(height: 12),
             Text("Motivo: ${reserva['motivo']}", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 20),
          
          // ACTIONS
          if (!isHistory) ...[
             Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text("Rechazar"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.withOpacity(0.5))),
                  ),
                  ElevatedButton.icon(
                    onPressed: onAprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text("Aprobar"), // Changed to verify Hot Reload
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                  ),
                ],
             )
          ] else ...[
             // Delete Button for History
             Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete, 
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      label: const Text("Eliminar Registro", style: TextStyle(color: Colors.red)),
                    )
                ],
             )
          ]
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBadge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [Icon(icon, size: 14, color: Colors.grey[600]), const SizedBox(width: 6), Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500))]),
    );
  }
}