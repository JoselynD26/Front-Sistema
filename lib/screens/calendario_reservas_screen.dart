import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';

class CalendarioReservasScreen extends StatefulWidget {
  const CalendarioReservasScreen({super.key});

  @override
  State<CalendarioReservasScreen> createState() => _CalendarioReservasScreenState();
}

class _CalendarioReservasScreenState extends State<CalendarioReservasScreen> {
  final api = ApiService();

  DateTime fechaActual = DateTime.now();
  List<dynamic> reservas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarReservas();
  }

  Future<void> cargarReservas() async {
    setState(() => cargando = true);

    reservas = await api.listarReservas(); // o listarMisReservas()

    setState(() => cargando = false);
  }

  List<dynamic> reservasDelDia() {
    return reservas.where((r) => r["fecha"] == fechaActual.toIso8601String().split("T")[0]).toList();
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case "aprobado":
        return Colors.green.withOpacity(0.8);
      case "cancelado":
        return Colors.red.withOpacity(0.8);
      default:
        return Colors.orange.withOpacity(0.8);
    }
  }

  int horaToInt(String hora) {
    return int.parse(hora.split(":")[0]);
  }

  @override
  Widget build(BuildContext context) {
    final reservasHoy = reservasDelDia();

    return AdminCRUDLayout(
      title: "Calendario de Reservas",
      subtitle: "Vista diaria de ocupación de aulas",
      // No Add button usually, unless we want to link to create reservation
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // NAV FECHA
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() => fechaActual = fechaActual.subtract(const Duration(days: 1)));
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            "${fechaActual.day}/${fechaActual.month}/${fechaActual.year}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          Text(
                            "Reservas del día",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() => fechaActual = fechaActual.add(const Duration(days: 1)));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // CALENDARIO
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: 15, // 07:00 a 22:00
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final hora = 7 + i;

                        // Buscar reservas que caen en esta hora
                        final reservasEnHora = reservasHoy.where((r) {
                          final inicio = horaToInt(r["hora_inicio"]);
                          final fin = horaToInt(r["hora_fin"]);
                          return hora >= inicio && hora < fin;
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hora columna
                              SizedBox(
                                width: 60,
                                child: Text(
                                  "$hora:00", 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.grey[700],
                                    fontSize: 16
                                  )
                                ),
                              ),
                              
                              // Reservas columna
                              Expanded(
                                child: reservasEnHora.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        "Disponible", 
                                        style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)
                                      ),
                                    )
                                  : Column(
                                      children: reservasEnHora.map((r) {
                                        return GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text("Detalle de Reserva"),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _DetailRow(label: "Docente", value: "${r['id_docente']}"), // Idealmente nombre
                                                    _DetailRow(label: "Aula", value: "${r['id_aula']}"),       // Idealmente nombre
                                                    _DetailRow(label: "Horario", value: "${r['hora_inicio']} - ${r['hora_fin']}"),
                                                    _DetailRow(label: "Estado", value: r['estado']),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text("Cerrar"),
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: colorEstado(r["estado"]).withOpacity(0.1),
                                              border: Border.all(color: colorEstado(r["estado"]).withOpacity(0.5)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.class_, size: 16, color: colorEstado(r["estado"])),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    "Docente ${r['id_docente']} | Aula ${r['id_aula']}",
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: colorEstado(r["estado"]),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    r["estado"].toString().toUpperCase(),
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}