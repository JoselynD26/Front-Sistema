import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'sala_form.dart';

class SalasScreen extends StatefulWidget {
  final int idSede;
  const SalasScreen({super.key, required this.idSede});

  @override
  _SalasScreenState createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  final _apiService = ApiService();
  List<dynamic> salas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSalas();
  }

  Future<void> _cargarSalas() async {
    try {
      final data = await _apiService.listarSalasPorSede(widget.idSede);
      print("SALAS RECIBIDAS: $data");
      setState(() {
        salas = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar salas")),
      );
    }
  }

  Future<void> _eliminarSala(int id) async {
    final ok = await _apiService.eliminarSala(id);
    if (ok) {
      _cargarSalas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sala eliminada")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar sala")),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? sala}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalaForm(
          sala: sala,
          idSede: widget.idSede,
          onSave: _cargarSalas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salas")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : salas.isEmpty
              ? const Center(child: Text("No hay salas registradas"))
              : ListView.builder(
                  itemCount: salas.length,
                  itemBuilder: (context, index) {
                    final s = salas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(s["id"].toString()),
                        ),
                        title: Text(s["nombre"]),
                        subtitle: Text("Sede: ${s["sede_nombre"] ?? "Sin sede"}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _abrirFormulario(sala: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarSala(s["id"]),
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