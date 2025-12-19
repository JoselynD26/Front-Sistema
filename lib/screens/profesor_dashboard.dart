import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/web_layout.dart';

class ProfesorDashboard extends StatefulWidget {
  final int docenteId;
  final String nombreProfesor;

  const ProfesorDashboard({
    super.key,
    required this.docenteId,
    required this.nombreProfesor,
  });

  @override
  _ProfesorDashboardState createState() => _ProfesorDashboardState();
}

class _ProfesorDashboardState extends State<ProfesorDashboard> {
  final _apiService = ApiService();
  List<dynamic> materias = [];
  List<dynamic> horarios = [];
  List<dynamic> reservas = [];
  Map<String, dynamic> miEscritorio = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final materiasData = await _apiService.obtenerMisMaterias(widget.docenteId);
      final horariosData = await _apiService.obtenerMiHorario(widget.docenteId);
      final reservasData = await _apiService.obtenerMisReservas(widget.docenteId);

      setState(() {
        materias = materiasData;
        horarios = horariosData;
        reservas = reservasData;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);

    return WebLayout(
      title: "Panel Profesor - ${widget.nombreProfesor}",
      child: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [yaviracBlue, yaviracOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 30, color: yaviracBlue),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bienvenido, ${widget.nombreProfesor}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Panel de Gestión Docente",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: "Cerrar Sesión",
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Grid de módulos
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildModuleCard(
                        "Mis Materias",
                        Icons.book,
                        "${materias.length} materias",
                        yaviracBlue,
                        () => _mostrarMaterias(),
                      ),
                      _buildModuleCard(
                        "Mi Horario",
                        Icons.schedule,
                        "${horarios.length} clases",
                        yaviracOrange,
                        () => _mostrarHorarios(),
                      ),
                      _buildModuleCard(
                        "Mis Reservas",
                        Icons.event_available,
                        "${reservas.length} reservas",
                        yaviracBlue,
                        () => _mostrarReservas(),
                      ),
                      _buildModuleCard(
                        "Reservar Aula",
                        Icons.add_circle,
                        "Nueva reserva",
                        yaviracOrange,
                        () => _crearReserva(),
                      ),
                      _buildModuleCard(
                        "Horario Aulas",
                        Icons.view_timeline,
                        "Ver ocupación",
                        yaviracBlue,
                        () => _verHorarioAulas(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModuleCard(
    String title,
    IconData icon,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMaterias() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mis Materias Asignadas"),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: materias.length,
            itemBuilder: (context, index) {
              final materia = materias[index];
              return ListTile(
                leading: const Icon(Icons.book, color: Color(0xFF1E3A8A)),
                title: Text(materia["nombre"]),
                subtitle: Text(
                  "Carreras: ${materia["carreras"].map((c) => c["nombre"]).join(", ")}",
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _mostrarHorarios() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mi Horario de Clases"),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: horarios.length,
            itemBuilder: (context, index) {
              final horario = horarios[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: Color(0xFFFF6B35)),
                  title: Text(horario["materia_nombre"]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fecha: ${horario["fecha"]}"),
                      Text("Hora: ${horario["hora"]}"),
                      Text("Aula: ${horario["aula_nombre"]}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: horario["estado"] == "activo" ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          horario["estado"].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (horario["estado"] == "activo")
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: "Cancelar clase",
                          onPressed: () => _cancelarClase(horario["id"]),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _mostrarReservas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mis Reservas de Aulas"),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index];
              Color statusColor = reserva["estado"] == "aprobada"
                  ? Colors.green
                  : reserva["estado"] == "pendiente"
                      ? Colors.orange
                      : Colors.red;

              return Card(
                child: ListTile(
                  leading: Icon(Icons.meeting_room, color: statusColor),
                  title: Text(reserva["aula_nombre"]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fecha: ${reserva["fecha"]}"),
                      Text("Hora: ${reserva["hora"]}"),
                      Text("Estado: ${reserva["estado"]}"),
                    ],
                  ),
                  trailing: reserva["estado"] == "pendiente"
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _cancelarReserva(reserva["id"]),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }



  void _crearReserva() {
    showDialog(
      context: context,
      builder: (context) => _FormularioReservaAula(docenteId: widget.docenteId),
    ).then((result) {
      if (result == true) {
        _cargarDatos(); // Recargar datos si se creó una reserva
      }
    });
  }



  void _cancelarReserva(int reservaId) async {
    final success = await _apiService.cancelarReservaAula(reservaId, widget.docenteId);
    if (success) {
      _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva cancelada")),
      );
    }
  }

  void _cerrarSesion() async {
    await _apiService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _verHorarioAulas() {
    showDialog(
      context: context,
      builder: (context) => _HorarioAulasDialog(),
    );
  }

  void _cancelarClase(int horarioId) async {
    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancelar Clase"),
        content: const Text("¿Estás seguro de que quieres cancelar esta clase?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sí, Cancelar"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Cancelar horario usando endpoint específico
      final success = await _apiService.cancelarHorario(horarioId);
      
      if (success) {
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Clase cancelada exitosamente"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al cancelar la clase"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _HorarioAulasDialog extends StatefulWidget {
  @override
  _HorarioAulasDialogState createState() => _HorarioAulasDialogState();
}

class _HorarioAulasDialogState extends State<_HorarioAulasDialog> {
  final _apiService = ApiService();
  final _fechaController = TextEditingController();
  List<dynamic> horarioAulas = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toString().split(' ')[0];
    _cargarHorarioAulas();
  }

  Future<void> _cargarHorarioAulas() async {
    if (_fechaController.text.isEmpty) return;
    setState(() => cargando = true);
    try {
      final datos = await _apiService.obtenerHorarioAulas(1, _fechaController.text);
      setState(() {
        horarioAulas = datos;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.view_timeline, color: Color(0xFF1E3A8A), size: 28),
                const SizedBox(width: 12),
                const Text(
                  "Horario de Ocupación de Aulas",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
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
                        _cargarHorarioAulas();
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
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: cargando ? null : _cargarHorarioAulas,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Actualizar"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: horarioAulas.length,
                      itemBuilder: (context, index) {
                        final aula = horarioAulas[index];
                        final ocupaciones = aula["ocupaciones"] as List;
                        return Card(
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.meeting_room,
                              color: aula["disponible"] ? Colors.green : Colors.red,
                            ),
                            title: Text(aula["nombre"]),
                            subtitle: Text(
                              "Capacidad: ${aula["capacidad"]} | ${ocupaciones.length} ocupación(es)",
                            ),
                            children: ocupaciones.isEmpty
                                ? [const ListTile(title: Text("Disponible todo el día"))]
                                : ocupaciones.map<Widget>((ocupacion) {
                                    return ListTile(
                                      leading: Icon(
                                        ocupacion["tipo"] == "reserva" 
                                            ? Icons.event_available 
                                            : Icons.school,
                                        color: ocupacion["tipo"] == "reserva" 
                                            ? Colors.orange 
                                            : Colors.blue,
                                      ),
                                      title: Text(
                                        "${ocupacion["hora_inicio"]} - ${ocupacion["hora_fin"]}",
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Profesor: ${ocupacion["profesor"]}"),
                                          Text("${ocupacion["tipo"] == "reserva" ? "Motivo" : "Materia"}: ${ocupacion["materia"]}"),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: ocupacion["tipo"] == "reserva" 
                                              ? Colors.orange 
                                              : Colors.blue,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ocupacion["tipo"].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioReservaAula extends StatefulWidget {
  final int docenteId;

  const _FormularioReservaAula({required this.docenteId});

  @override
  _FormularioReservaAulaState createState() => _FormularioReservaAulaState();
}

class _FormularioReservaAulaState extends State<_FormularioReservaAula> {
  final _apiService = ApiService();
  final _fechaController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFinController = TextEditingController();
  final _motivoController = TextEditingController(text: "Clase adicional");
  
  List<dynamic> aulasDisponibles = [];
  int? aulaSeleccionada;
  bool cargando = false;
  bool buscandoAulas = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.meeting_room, color: Color(0xFFFF6B35), size: 28),
                const SizedBox(width: 12),
                const Text(
                  "Reservar Aula",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Formulario de búsqueda
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _horaInicioController,
                            decoration: const InputDecoration(
                              labelText: "Hora Inicio",
                              hintText: "14:00",
                              prefixIcon: Icon(Icons.access_time),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _horaFinController,
                            decoration: const InputDecoration(
                              labelText: "Hora Fin",
                              hintText: "16:00",
                              prefixIcon: Icon(Icons.access_time_filled),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: buscandoAulas ? null : _buscarAulasDisponibles,
                        icon: buscandoAulas
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(buscandoAulas ? "Buscando..." : "Buscar Aulas Disponibles"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tabla de aulas disponibles
            if (aulasDisponibles.isNotEmpty) ...[
              const Text(
                "Aulas Disponibles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Aula",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Capacidad",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Tipo",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Seleccionar",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: aulasDisponibles.length,
                          itemBuilder: (context, index) {
                            final aula = aulasDisponibles[index];
                            final isSelected = aulaSeleccionada == aula["id"];
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF6B35).withOpacity(0.1) : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.meeting_room,
                                            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            aula["nombre"],
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? const Color(0xFFFF6B35) : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text("${aula["capacidad"]} personas"),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          aula["tipo"] ?? "Aula",
                                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Radio<int>(
                                          value: aula["id"],
                                          groupValue: aulaSeleccionada,
                                          onChanged: (value) => setState(() => aulaSeleccionada = value),
                                          activeColor: const Color(0xFFFF6B35),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => setState(() => aulaSeleccionada = aula["id"]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Campo de motivo
              TextField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: "Motivo de la reserva",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ] else if (!buscandoAulas && _fechaController.text.isNotEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No se encontraron aulas disponibles",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Intenta con otra fecha u horario",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Ingresa fecha y horarios para buscar aulas",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Botones de acción
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: (aulaSeleccionada != null && !cargando) ? _crearReserva : null,
                  icon: cargando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(cargando ? "Creando..." : "Confirmar Reserva"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarAulasDisponibles() async {
    if (_fechaController.text.isEmpty || _horaInicioController.text.isEmpty || _horaFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa fecha, hora de inicio y hora de fin")),
      );
      return;
    }

    setState(() => buscandoAulas = true);

    try {
      final aulas = await _apiService.obtenerAulasDisponibles(
        _fechaController.text,
        _horaInicioController.text,
        1, // sede_id fijo por ahora
      );

      setState(() {
        aulasDisponibles = aulas;
        aulaSeleccionada = null;
        buscandoAulas = false;
      });

      if (aulas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hay aulas disponibles en ese horario")),
        );
      }
    } catch (e) {
      setState(() => buscandoAulas = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _crearReserva() async {
    setState(() => cargando = true);

    try {
      final success = await _apiService.crearReservaAulaConRango(
        _fechaController.text,
        _horaInicioController.text,
        _horaFinController.text,
        aulaSeleccionada!,
        widget.docenteId,
        _motivoController.text,
      );

      setState(() => cargando = false);

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reserva creada exitosamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al crear reserva")),
        );
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}