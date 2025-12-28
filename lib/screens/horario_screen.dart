import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_crud_layout.dart';
import 'horario_form.dart';
import 'horario_semanal_form.dart';
import 'horario_import_screen.dart';

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

  void _abrirFormularioSemanal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HorarioSemanalForm(
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
    return DefaultTabController(
      length: 2,
      child: AdminCRUDLayout(
        title: "Horarios de Clases",
        subtitle: "Gestión de horarios y plantillas",
        idSede: widget.idSede,
        scrollable: false, // 🔥 Deshabilitar scroll para el TabView
        onAdd: () => _abrirFormularioSemanal(),
        addLabel: "Crear Horario Semanal",
        filters: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text("Agregar Clase Individual"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      side: const BorderSide(color: Colors.blue),
                    ),
                    onPressed: () => _abrirFormulario(),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text("IMPORTAR DESDE PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo,
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HorarioImportScreen(idSede: widget.idSede),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(icon: Icon(Icons.list), text: "Clases (Eventos)"),
                Tab(icon: Icon(Icons.date_range), text: "Plantilla Semanal"),
              ],
            ),
          ],
        ),
        child: TabBarView(
          children: [
            _buildListaEventos(),
            _buildListaPlantillas(),
          ],
        ),
      ),
    );
  }

  Widget _buildListaEventos() {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (clases.isEmpty) return const Center(child: Text("No hay clases registradas"));

    final clasesPorDocente = _agruparPorDocente(clases);

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: clasesPorDocente.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = clasesPorDocente.entries.elementAt(index);
        final idDocente = entry.key;
        final listaClases = entry.value;
        final nombreDocente = listaClases.isNotEmpty && listaClases.first["docente_nombre"] != null
            ? listaClases.first["docente_nombre"]
            : "Docente ID: $idDocente";

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(nombreDocente, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${listaClases.length} clases puntuales"),
            children: listaClases.map((c) {
               return ListTile(
                 leading: const Icon(Icons.class_, color: Colors.grey, size: 20),
                 title: Text(c["materia_nombre"] ?? "Materia ID: ${c["id_materia"]}"),
                 subtitle: Text("${c["fecha"]} | ${c["hora_inicio"]} - ${c["hora_fin"]}"),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     _buildEstadoBadge(c["estado"]),
                     IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _eliminarClase(c["id"])),
                   ],
                 ),
               );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildListaPlantillas() {
    // Aquí cargaremos los docentes y permitiremos ver sus horarios semanales
    return _PlantillaSemanalView(idSede: widget.idSede);
  }

  Widget _buildEstadoBadge(String? estado) {
    Color color = Colors.grey;
    if (estado == "confirmado" || estado == "activo") color = Colors.green;
    if (estado == "cancelado") color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        estado?.toUpperCase() ?? "N/A",
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _PlantillaSemanalView extends StatefulWidget {
  final int idSede;
  const _PlantillaSemanalView({required this.idSede});

  @override
  State<_PlantillaSemanalView> createState() => _PlantillaSemanalViewState();
}

class _PlantillaSemanalViewState extends State<_PlantillaSemanalView> {
  final ApiService _api = ApiService();
  List<dynamic> docentes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
  }

  Future<void> _cargarDocentes() async {
    try {
      final data = await _api.listarDocentesPorSede(widget.idSede);
      data.sort((a, b) => (a["nombres"]??"").toString().compareTo(b["nombres"]??"")); 
      setState(() {
        docentes = data;
        loading = false;
      });
    } catch (e) {
      if(mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (docentes.isEmpty) return const Center(child: Text("No hay docentes"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docentes.length,
      itemBuilder: (ctx, i) {
        final d = docentes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(child: Text(d["nombres"][0])),
            title: Text("${d["apellidos"]} ${d["nombres"]}"),
            subtitle: const Text("Ver horario semanal"),
            children: [
              FutureBuilder<List<dynamic>>(
                future: _api.obtenerHorarioDocente(d["id"]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(20), child: Text("Error cargando horario"));
                  
                  final horarios = snapshot.data ?? [];
                  if (horarios.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("Sin horario asignado."));

                  return Column(
                    children: horarios.map((h) => ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text("${h['dia']} ${h['hora_inicio']} - ${h['hora_fin']}"),
                      subtitle: Text("${h['materia_nombre'] ?? 'Materia'} (Aula ${h['aula_nombre']??'?'})"),
                      trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    )).toList(),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}
