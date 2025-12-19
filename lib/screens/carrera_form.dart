import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CarrerasScreen extends StatefulWidget {
  final int idSede;
  const CarrerasScreen({super.key, required this.idSede});

  @override
  _CarrerasScreenState createState() => _CarrerasScreenState();
}

class _CarrerasScreenState extends State<CarrerasScreen> {
  final _apiService = ApiService();
  List<dynamic> carreras = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    try {
      final data = await _apiService.listarCarreras();
      setState(() {
        carreras = data;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        carreras = [];
        cargando = false;
      });
    }
  }

  void _mostrarFormulario() {
    final nombreController = TextEditingController();
    final codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nueva Carrera'),
        content: SizedBox(
          height: 150,
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: codigoController,
                decoration: InputDecoration(labelText: 'Código'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final datos = {
                "nombre": nombreController.text,
                "codigo": codigoController.text.isEmpty ? "AUTO" : codigoController.text,
                "sede_ids": [widget.idSede],
              };
              
              final success = await _apiService.crearCarrera(datos);
              Navigator.pop(context);
              
              if (success) {
                _cargarCarreras();
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carreras")),
      body: cargando
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: carreras.length,
              itemBuilder: (context, index) {
                final carrera = carreras[index];
                return ListTile(
                  title: Text(carrera["nombre"] ?? ""),
                  subtitle: Text("Código: ${carrera["codigo"] ?? "AUTO"}"),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        child: Icon(Icons.add),
      ),
    );
  }
}