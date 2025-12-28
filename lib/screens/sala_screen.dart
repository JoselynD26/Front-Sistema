import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import '../widgets/admin_table.dart';
import 'sala_form_screen.dart';

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
    if (!mounted) return;
    try {
      final data = await _apiService.listarSalasPorSede(widget.idSede);
      if (mounted) {
        setState(() {
          salas = data;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al cargar salas")),
        );
      }
    }
  }

  Future<void> _eliminarSala(int id) async {
    final ok = await _apiService.eliminarSala(id);
    if (mounted) {
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
  }

  void _abrirFormulario({Map<String, dynamic>? sala}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalaFormScreen(
          sala: sala,
          idSede: widget.idSede,
        ),
      ),
    );

    if (result == true) {
      _cargarSalas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCRUDLayout(
      title: "Salas",
      subtitle: "Gestión de laboratorios y salas especiales",
      onAdd: () => _abrirFormulario(),
      child: AdminTable(
        isLoading: cargando,
        columns: const [
          DataColumn(label: Text("Nombre")),
          DataColumn(label: Text("Sede")),
          DataColumn(label: Text("Acciones")),
        ],
        rows: salas.map((s) {
          return DataRow(cells: [
            DataCell(Text(s["nombre"], style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(s["sede_nombre"] ?? "Sin sede")),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _abrirFormulario(sala: s),
                  tooltip: "Editar",
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _eliminarSala(s["id"]),
                  tooltip: "Eliminar",
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}