import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'horario_form.dart';

class HorarioScreen extends StatefulWidget {
  final int idSede;
  const HorarioScreen({super.key, required this.idSede});

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> clases = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarClases();
  }

  Future<void> _cargarClases() async {
    try {
      final data = await _apiService.listarHorariosPorSede(widget.idSede);
      setState(() {
        clases = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar clases: $e")),
      );
    }
  }

  Future<void> _eliminarClase(int id) async {
    final ok = await _apiService.eliminarHorario(id);
    if (ok) {
      _cargarClases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clase eliminada")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? clase}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HorarioForm(
          horario: clase,
          idSede: widget.idSede,
          onSave: _cargarClases,
        ),
      ),
    );
  }

  // 🔥 AGRUPAR CLASES POR DOCENTE
  Map<int, List<dynamic>> _agruparPorDocente(List<dynamic> clases) {
    final Map<int, List<dynamic>> resultado = {};

    for (var c in clases) {
      final int idDocente = c["id_docente"];
      resultado.putIfAbsent(idDocente, () => []);
      resultado[idDocente]!.add(c);
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (clases.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No hay clases registradas")),
      );
    }

    final clasesPorDocente = _agruparPorDocente(clases);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Clases por Docente"),
      ),
      body: ListView(
        children: clasesPorDocente.entries.map((entry) {
          final idDocente = entry.key;
          final listaClases = entry.value;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ExpansionTile(
              leading: const Icon(Icons.person),
              title: Text("Docente ID: $idDocente"),
              subtitle: Text("Clases: ${listaClases.length}"),
              children: listaClases.map((c) {
                return ListTile(
                  title: Text("Materia ID: ${c["id_materia"]}"),
                  subtitle: Text(
                    "📅 ${c["fecha"]}\n⏰ ${c["hora_inicio"]} - ${c["hora_fin"]}",
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c["estado"],
                        style: TextStyle(
                          color: c["estado"] == "cancelado"
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _abrirFormulario(clase: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarClase(c["id"]),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
