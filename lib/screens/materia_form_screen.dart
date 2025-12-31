import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_form_layout.dart';

class MateriaFormScreen extends StatefulWidget {
  final int idSede;
  final Map<String, dynamic>? materia;

  const MateriaFormScreen({
    super.key,
    required this.idSede,
    this.materia,
  });

  @override
  State<MateriaFormScreen> createState() => _MateriaFormScreenState();
}

class _MateriaFormScreenState extends State<MateriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  final _nombreController = TextEditingController();
  List<int> carrerasSeleccionadas = [];
  List<int> docentesSeleccionados = [];

  List<dynamic> carrerasDisponibles = [];
  List<dynamic> docentesDisponibles = [];

  bool cargando = true;
  bool guardando = false;
  final Color _primaryColor = const Color(0xFFEC4899); // Pink 500

  @override
  void initState() {
    super.initState();
    if (widget.materia != null) {
      _nombreController.text = widget.materia!["nombre"] ?? "";
      carrerasSeleccionadas = List<int>.from(
        (widget.materia!["carreras"] ?? []).map((c) => c["id"]),
      );
      docentesSeleccionados = List<int>.from(
        (widget.materia!["docentes"] ?? []).map((d) => d["id"]),
      );
    }
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    try {
      final cArr = await _apiService.listarCarreras();
      final dArr = await _apiService.listarDocentesPorSede(widget.idSede);

      cArr.sort((a, b) => (a['nombre'] ?? "").toString().toLowerCase().compareTo((b['nombre'] ?? "").toString().toLowerCase()));
      
      final Map<int, dynamic> uniqueDocs = {};
      for (var d in dArr) {
        if (d['id'] != null) uniqueDocs[d['id']] = d;
      }
      final sortedDocs = uniqueDocs.values.toList();
      sortedDocs.sort((a, b) {
        final apeA = (a['apellidos'] ?? '').toString().trim().toLowerCase();
        final apeB = (b['apellidos'] ?? '').toString().trim().toLowerCase();
        final cmp = apeA.compareTo(apeB);
        if (cmp != 0) return cmp;
        
        final nomA = (a['nombres'] ?? '').toString().trim().toLowerCase();
        final nomB = (b['nombres'] ?? '').toString().trim().toLowerCase();
        return nomA.compareTo(nomB);
      });

      setState(() {
        carrerasDisponibles = cArr.where((c) => 
          (c["sede_ids"] as List).contains(widget.idSede)
        ).toList();
        docentesDisponibles = sortedDocs;
        cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (carrerasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una carrera"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => guardando = true);

    final datos = {
      "nombre": _nombreController.text.trim(),
      "carrera_ids": carrerasSeleccionadas,
      "docente_ids": docentesSeleccionados,
      "sede_ids": [widget.idSede],
    };

    try {
      bool ok;
      if (widget.materia == null) {
        ok = await _apiService.crearMateria(datos);
      } else {
        ok = await _apiService.actualizarMateria(widget.materia!["id"], datos);
      }

      if (mounted) {
        setState(() => guardando = false);
        if (ok) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al guardar materia"), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.materia != null;

    return AdminFormLayout(
      title: esEdicion ? "Editar Materia" : "Nueva Materia",
      subtitle: "Asigne la materia a las carreras correspondientes y defina el personal docente.",
      icon: Icons.book_rounded,
      primaryColor: _primaryColor,
      isLoading: cargando || guardando,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: premiumInputDecoration(
                  label: "Nombre de la Materia",
                  hint: "Ej. Programación Avanzada",
                  icon: Icons.label_important_rounded,
                  primaryColor: _primaryColor,
                ),
                validator: (v) => v!.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 32),
              
              const Text(
                "Carreras Relacionadas",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              _buildCarrerasSelector(),
              
              const SizedBox(height: 32),
              
              const Text(
                "Personal Docente",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              _buildDocentesSelector(),
            ],
          ),
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: (cargando || guardando) ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.4),
          ),
          child: Text(
            esEdicion ? "GUARDAR CAMBIOS" : "CREAR MATERIA",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text("Cancelar y volver"),
        ),
      ],
    );
  }

  Widget _buildCarrerasSelector() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          decoration: premiumInputDecoration(
            label: "Agregar Carrera",
            hint: "Seleccione una carrera...",
            icon: Icons.school_rounded,
            primaryColor: _primaryColor,
          ),
          items: carrerasDisponibles.map((c) => DropdownMenuItem<int>(
            value: c["id"],
            child: Text(c["nombre"]),
          )).toList(),
          onChanged: (v) {
            if (v != null && !carrerasSeleccionadas.contains(v)) {
              setState(() => carrerasSeleccionadas.add(v));
            }
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: carrerasSeleccionadas.map((id) {
            final c = carrerasDisponibles.firstWhere(
              (x) => x["id"] == id, 
              orElse: () => null
            );
            if (c == null) return const SizedBox.shrink();
            
            return Chip(
              label: Text(c["nombre"] ?? "Sin Nombre"),
              backgroundColor: _primaryColor.withOpacity(0.1),
              deleteIconColor: _primaryColor,
              onDeleted: () => setState(() => carrerasSeleccionadas.remove(id)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).whereType<Widget>().toList(),
        ),
      ],
    );
  }

  Widget _buildDocentesSelector() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          decoration: premiumInputDecoration(
            label: "Agregar Docente",
            hint: "Seleccione un docente...",
            icon: Icons.person_add_rounded,
            primaryColor: _primaryColor,
          ),
          items: docentesDisponibles.map((d) => DropdownMenuItem<int>(
            value: d["id"],
            child: Text("${d["apellidos"]} ${d["nombres"]}"),
          )).toList(),
          onChanged: (v) {
            if (v != null && !docentesSeleccionados.contains(v)) {
              setState(() => docentesSeleccionados.add(v));
            }
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docentesSeleccionados.map((id) {
            final d = docentesDisponibles.firstWhere(
              (x) => x["id"] == id, 
              orElse: () => null
            );
            if (d == null) return const SizedBox.shrink();

            return Chip(
              label: Text("${d["apellidos"]} ${d["nombres"]}"),
              backgroundColor: _primaryColor.withOpacity(0.1),
              deleteIconColor: _primaryColor,
              onDeleted: () => setState(() => docentesSeleccionados.remove(id)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }).whereType<Widget>().toList(),
        ),
      ],
    );
  }
}
