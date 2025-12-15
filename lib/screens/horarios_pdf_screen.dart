import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';

class HorariosPdfScreen extends StatefulWidget {
  const HorariosPdfScreen({super.key});

  @override
  State<HorariosPdfScreen> createState() => _HorariosPdfScreenState();
}

class _HorariosPdfScreenState extends State<HorariosPdfScreen> {
  final api = ApiService();

  Future<void> _subirPdf(String tipo) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"],
    );

    if (result == null) return;

    final file = result.files.single;

    bool ok = false;

    // ✅ WEB usa bytes
    if (file.bytes != null) {
      ok = await api.subirPdfHorarioWeb(
        tipo,
        file.bytes!,
        file.name,
      );
    }

    // ✅ ANDROID / iOS usa path
    else if (file.path != null) {
      ok = await api.subirPdfHorario(
        tipo,
        file.path!,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "PDF subido correctamente" : "Error al subir PDF"),
      ),
    );
  }

  Future<void> _verPdf(String tipo) async {
    // ✅ Obtener bytes desde FastAPI
    final bytes = await api.obtenerPdfBytes(tipo);

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar el PDF")),
      );
      return;
    }

    // ✅ Abrir visor con bytes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(bytes: bytes, tipo: tipo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Horarios PDF")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Ver PDFs",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => _verPdf("aulas"),
            child: const Text("Ver Horarios de Aulas"),
          ),
          ElevatedButton(
            onPressed: () => _verPdf("docentes"),
            child: const Text("Ver Horarios de Docentes"),
          ),
          ElevatedButton(
            onPressed: () => _verPdf("cursos"),
            child: const Text("Ver Horarios de Cursos"),
          ),

          const SizedBox(height: 30),
          const Text(
            "Subir PDFs",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => _subirPdf("aulas"),
            child: const Text("Subir PDF de Aulas"),
          ),
          ElevatedButton(
            onPressed: () => _subirPdf("docentes"),
            child: const Text("Subir PDF de Docentes"),
          ),
          ElevatedButton(
            onPressed: () => _subirPdf("cursos"),
            child: const Text("Subir PDF de Cursos"),
          ),
        ],
      ),
    );
  }
}