import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';

class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

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

    return WebLayout(
      title: "Gestión de Reservas - Admin",
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pending_actions, color: yaviracBlue, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      "Reservas Pendientes de Aprobación",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: yaviracBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Revisa y aprueba las solicitudes de reserva de aulas de los profesores",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                if (reservasPendientes.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text(
                          "No hay reservas pendientes",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reservasPendientes.length,
                    itemBuilder: (context, index) {
                      final reserva = reservasPendientes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: yaviracOrange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.meeting_room,
                                      color: yaviracOrange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                                        Text(
                                          "Profesor: ${reserva["docente_nombre"]}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, 
                                       size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Fecha: ${reserva["fecha"]}",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, 
                                       size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Hora: ${reserva["hora"]}",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _rechazarReserva(reserva["id"]),
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    label: const Text(
                                      "Rechazar",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _aprobarReserva(reserva["id"]),
                                    icon: const Icon(Icons.check, color: Colors.white),
                                    label: const Text(
                                      "Aprobar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}