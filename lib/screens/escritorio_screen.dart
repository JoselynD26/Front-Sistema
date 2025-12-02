import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'escritorio_form.dart';

class EscritoriosScreen extends StatefulWidget {
  final int idSede;
  const EscritoriosScreen({super.key, required this.idSede});

  @override
  _EscritoriosScreenState createState() => _EscritoriosScreenState();
}

class _EscritoriosScreenState extends State<EscritoriosScreen> {
  final _apiService = ApiService();
  List<dynamic> escritorios = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEscritorios();
  }

  Future<void> _cargarEscritorios() async {
    try {
      final data = await _apiService.listarEscritoriosPorSede(widget.idSede);
      print("ESCRITORIOS RECIBIDOS: $data"); // 👈 Depuración
      setState(() {
        escritorios = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar escritorios")),
      );
    }
  }

  Future<void> _eliminarEscritorio(int id) async {
    final ok = await _apiService.eliminarEscritorio(id);
    if (ok) {
      _cargarEscritorios();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escritorio eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar escritorio")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? escritorio}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EscritorioForm(
          escritorio: escritorio,
          idSede: widget.idSede,
          onSave: _cargarEscritorios,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escritorios")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : escritorios.isEmpty
              ? const Center(child: Text("No hay escritorios registrados"))
              : ListView.builder(
                  itemCount: escritorios.length,
                  itemBuilder: (context, index) {
                    final e = escritorios[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(e["id"].toString()),
                        ),
                        title: Text("${e["codigo"]} - ${e["estado"]}"),
                        subtitle: Text(
                          "Jornada: ${e["jornada"]}\n"
                          "Sala: ${e["sala_nombre"] ?? "Sin sala"} | "
                          "Carrera: ${e["carrera_nombre"] ?? "Sin carrera"} | "
                          "Docente: ${e["docente_nombre"] ?? "Sin docente"}",
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _abrirFormulario(escritorio: e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarEscritorio(e["id"]),
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