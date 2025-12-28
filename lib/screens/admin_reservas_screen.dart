import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

class AdminReservasScreen extends StatefulWidget {
  final int? idSede;
  const AdminReservasScreen({super.key, this.idSede});

  @override
  _AdminReservasScreenState createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> {
  final _apiService = ApiService();
  List<dynamic> reservasPendientes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarReservas();
  }

  Future<void> _cargarReservas() async {
    try {
      final data = await _apiService.obtenerReservasPendientes();
      setState(() {
        reservasPendientes = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar reservas: $e")),
      );
    }
  }

  Future<void> _aprobarReserva(int reservaId) async {
    final success = await _apiService.aprobarReserva(reservaId);
    if (success) {
      _cargarReservas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reserva aprobada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al aprobar reserva"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rechazarReserva(int reservaId) async {
    final success = await _apiService.rechazarReserva(reservaId);
    if (success) {
      _cargarReservas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reserva rechazada"),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al rechazar reserva"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);

    return AdminCRUDLayout(
      title: "Gestión de Reservas",
      subtitle: "Aprueba o rechaza solicitudes de reserva",
      idSede: widget.idSede,
      // No Add button needed here
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : reservasPendientes.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(48),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        "No hay reservas pendientes",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reservasPendientes.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final reserva = reservasPendientes[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                                decoration: BoxDecoration(
                                  color: yaviracOrange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.meeting_room_rounded,
                                  color: yaviracOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Aula: ${reserva["aula_nombre"]}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: yaviracBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Profesor: ${reserva["docente_nombre"]}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  "PENDIENTE",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _InfoBadge(icon: Icons.calendar_today, text: reserva["fecha"]),
                              const SizedBox(width: 16),
                              _InfoBadge(icon: Icons.access_time, text: reserva["hora"]),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _rechazarReserva(reserva["id"]),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text("Rechazar"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _aprobarReserva(reserva["id"]),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text("Aprobar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}