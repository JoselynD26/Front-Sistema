import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

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
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPendientes() async {
    try {
      final data = await _apiService.obtenerReservasPendientes();
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

  Future<void> _aprobarReserva(int reservaId) async {
    final success = await _apiService.aprobarReserva(reservaId);
    if (success) {
      _cargarPendientes();
      _cargarHistorial(); // Refrescar historial para verla aprobada
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva aprobada"), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al aprobar")));
    }
  }

  Future<void> _rechazarReserva(int reservaId) async {
    final success = await _apiService.rechazarReserva(reservaId);
    if (success) {
      _cargarPendientes();
      _cargarHistorial();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva rechazada"), backgroundColor: Colors.orange));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al rechazar")));
    }
  }
  
  Future<void> _eliminarReserva(int reservaId) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Estás seguro de eliminar este registro del historial? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: ()=> Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      )
    );
    
    if (confirm == true) {
       final success = await _apiService.eliminarReserva(reservaId);
       if (success) {
         _cargarHistorial();
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro eliminado"), backgroundColor: Colors.red));
       } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al eliminar")));
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
          onAprove: () => _aprobarReserva(r['id']),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: yaviracBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Profesor: ${reserva["docente_nombre"] ?? 'Desconocido'}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
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
          Row(
            children: [
              _InfoBadge(icon: Icons.calendar_today, text: reserva["fecha"] ?? "N/A"),
              const SizedBox(width: 16),
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
             Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text("Rechazar"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.withOpacity(0.5))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onAprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text("Aprobar"),
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