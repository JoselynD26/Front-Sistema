import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario de Reservas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarReservas,
          )
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // NAV FECHA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() => fechaActual = fechaActual.subtract(const Duration(days: 1)));
                      },
                    ),
                    Text(
                      "${fechaActual.day}/${fechaActual.month}/${fechaActual.year}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() => fechaActual = fechaActual.add(const Duration(days: 1)));
                      },
                    ),
                  ],
                ),

                const Divider(),

                // CALENDARIO
                Expanded(
                  child: ListView.builder(
                    itemCount: 15, // 07:00 a 22:00
                    itemBuilder: (_, i) {
                      final hora = 7 + i;

                      // Buscar reservas que caen en esta hora
                      final reservasEnHora = reservasHoy.where((r) {
                        final inicio = horaToInt(r["hora_inicio"]);
                        final fin = horaToInt(r["hora_fin"]);
                        return hora >= inicio && hora < fin;
                      }).toList();

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$hora:00", style: const TextStyle(fontWeight: FontWeight.bold)),

                            const SizedBox(height: 6),

                            if (reservasEnHora.isEmpty)
                              const Text("— Libre", style: TextStyle(color: Colors.grey))
                            else
                              Column(
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
                                              Text("Docente: ${r['id_docente']}"),
                                              Text("Aula: ${r['id_aula']}"),
                                              Text("Escritorio: ${r['id_escritorio']}"),
                                              Text("Inicio: ${r['hora_inicio']}"),
                                              Text("Fin: ${r['hora_fin']}"),
                                              Text("Estado: ${r['estado']}"),
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
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: colorEstado(r["estado"]),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Docente ${r['id_docente']} | Aula ${r['id_aula']}",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }).toList(),
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