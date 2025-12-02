import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'horario_form.dart'; // formulario para crear/editar

class HorariosScreen extends StatefulWidget {
  final int idSede;
  const HorariosScreen({super.key, required this.idSede});

  @override
  _HorariosScreenState createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final _apiService = ApiService();
  List<dynamic> horarios = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    try {
      final data = await _apiService.listarHorariosPorSede(widget.idSede);
      setState(() {
        horarios = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar horarios: $e")),
      );
    }
  }

  Future<void> _eliminarHorario(int id) async {
    final ok = await _apiService.eliminarHorario(id);
    if (ok) {
      _cargarHorarios();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Horario eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar horario")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? horario}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HorarioForm(
          horario: horario,
          idSede: widget.idSede,
          onSave: _cargarHorarios,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Horarios")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : horarios.isEmpty
              ? const Center(child: Text("No hay horarios registrados"))
              : ListView.builder(
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    final h = horarios[index];

                    // Ajusta las claves según lo que devuelva tu backend
                    final fecha = h["fecha"] ?? "";
                    final hora = h["hora"] ?? "";
                    final estado = h["estado"] ?? "";
                    final materiaId = h["id_materia"] ?? "";
                    final docenteId = h["id_docente"] ?? "";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(h["id"].toString())),
                        title: Text("Materia ID: $materiaId - Docente ID: $docenteId"),
                        subtitle: Text("Fecha: $fecha - Hora: $hora"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              estado,
                              style: TextStyle(
                                color: estado == "cancelado" ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _abrirFormulario(horario: h),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarHorario(h["id"]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}