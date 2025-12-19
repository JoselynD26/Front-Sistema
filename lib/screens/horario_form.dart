import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HorarioForm extends StatefulWidget {
  final Map? horario;
  final int idSede;
  final Function? onSave;

  const HorarioForm({
    super.key,
    this.horario,
    required this.idSede,
    this.onSave,
  });

  @override
  _HorarioFormState createState() => _HorarioFormState();
}

class _HorarioFormState extends State<HorarioForm> {
  final _fechaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  
  final apiService = ApiService();
  bool cargando = false;
  String? mensaje;
  
  List<dynamic> docentes = [];
  List<dynamic> materias = [];
  List<dynamic> aulas = [];
  
  int? docenteSeleccionado;
  int? materiaSeleccionada;
  int? aulaSeleccionada;
  String estado = "activo";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    if (widget.horario != null) {
      _fechaController.text = widget.horario!['fecha'] ?? "";
      _horaInicioController.text = widget.horario!['hora_inicio'] ?? widget.horario!['hora'] ?? "";
      _horaFinController.text = widget.horario!['hora_fin'] ?? "";
      estado = widget.horario!['estado'] ?? "activo";
      docenteSeleccionado = widget.horario!['id_docente'];
      materiaSeleccionada = widget.horario!['id_materia'];
      aulaSeleccionada = widget.horario!['id_aula'];
    }
  }
  
  Future<void> _cargarDatos() async {
    try {
      final docentesData = await apiService.listarDocentesPorSede(widget.idSede);
      final materiasData = await apiService.listarMateriasPorSede(widget.idSede);
      final aulasData = await apiService.listarAulasPorSede(widget.idSede);
      
      setState(() {
        docentes = docentesData;
        materias = materiasData;
        aulas = aulasData;
      });
    } catch (e) {
      setState(() => mensaje = "Error al cargar datos: $e");
    }
  }

  Future<void> _guardar() async {
    if (_fechaController.text.isEmpty || _horaInicioController.text.isEmpty || _horaFinController.text.isEmpty) {
      setState(() => mensaje = "Fecha, hora de inicio y hora de fin son obligatorias");
      return;
    }

    if (docenteSeleccionado == null ||
        materiaSeleccionada == null ||
        aulaSeleccionada == null) {
      setState(() => mensaje = "Docente, Materia y Aula son obligatorios");
      return;
    }

    setState(() => cargando = true);

    final datos = {
      "fecha": _fechaController.text.trim(),
      "hora_inicio": _horaInicioController.text.trim(),
      "hora_fin": _horaFinController.text.trim(),
      "estado": estado,
      "id_docente": docenteSeleccionado!,
      "id_materia": materiaSeleccionada!,
      "id_aula": aulaSeleccionada!,
      "id_sede": widget.idSede,
    };

    bool success;
    if (widget.horario == null) {
      success = await apiService.crearHorario(datos);
    } else {
      success = await apiService.actualizarHorario(widget.horario!['id'], datos);
    }

    setState(() {
      cargando = false;
      mensaje = success ? "Guardado con éxito" : "Error al guardar";
    });

    if (success && widget.onSave != null) {
      widget.onSave!();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.horario == null ? "Nuevo Horario" : "Editar Horario"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Sede ID: ${widget.idSede}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            InkWell(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (fecha != null) {
                  setState(() {
                    _fechaController.text = fecha.toString().split(' ')[0];
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      _fechaController.text.isEmpty 
                          ? "Seleccionar fecha" 
                          : _fechaController.text,
                      style: TextStyle(
                        color: _fechaController.text.isEmpty 
                            ? Colors.grey 
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _horaInicioController,
                    decoration: const InputDecoration(
                      labelText: "Hora Inicio (HH:MM)",
                      hintText: "14:00",
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _horaFinController,
                    decoration: const InputDecoration(
                      labelText: "Hora Fin (HH:MM)",
                      hintText: "16:00",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: estado,
              items: const [
                DropdownMenuItem(value: "activo", child: Text("Activo")),
                DropdownMenuItem(value: "cancelado", child: Text("Cancelado")),
              ],
              onChanged: (value) => setState(() => estado = value!),
              decoration: const InputDecoration(labelText: "Estado"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: docenteSeleccionado,
              items: docentes.map<DropdownMenuItem<int>>((docente) {
                return DropdownMenuItem<int>(
                  value: docente["id"],
                  child: Text("${docente["nombres"]} ${docente["apellidos"]}"),
                );
              }).toList(),
              onChanged: (value) => setState(() => docenteSeleccionado = value),
              decoration: const InputDecoration(labelText: "Docente"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: materiaSeleccionada,
              items: materias.map<DropdownMenuItem<int>>((materia) {
                return DropdownMenuItem<int>(
                  value: materia["id"],
                  child: Text(materia["nombre"]),
                );
              }).toList(),
              onChanged: (value) => setState(() => materiaSeleccionada = value),
              decoration: const InputDecoration(labelText: "Materia"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: aulaSeleccionada,
              items: aulas.map<DropdownMenuItem<int>>((aula) {
                return DropdownMenuItem<int>(
                  value: aula["id"],
                  child: Text("${aula["nombre"]} (Capacidad: ${aula["capacidad"]})"),
                );
              }).toList(),
              onChanged: (value) => setState(() => aulaSeleccionada = value),
              decoration: const InputDecoration(labelText: "Aula"),
            ),

            const SizedBox(height: 20),

            if (cargando) const Center(child: CircularProgressIndicator()),
            if (mensaje != null)
              Center(
                child: Text(
                  mensaje!,
                  style: TextStyle(
                    color: mensaje == "Guardado con éxito" ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ElevatedButton(
              onPressed: cargando ? null : _guardar,
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }
}