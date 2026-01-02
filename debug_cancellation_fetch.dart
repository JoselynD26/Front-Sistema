
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final fecha = "2026-01-02";
  final sedeId = 1;
  
  final candidates = [
    "http://localhost:8000/horarios/cancelados/", // No params
    "http://localhost:8000/horarios/cancelados/?sede_id=$sedeId", // Sede only
    "http://localhost:8000/horarios/cancelados/?fecha=$fecha", // Date only
    "http://localhost:8000/horarios/cancelados/?sede_id=$sedeId&fecha=$fecha", // Original
    "http://localhost:8000/horarios/cancelados/?sede_id=0&fecha=$fecha", // Zero Sede
    "http://localhost:8000/horarios/cancelados/?sede_id=null&fecha=$fecha", // Null Sede
  ];

  for (var c in candidates) {
    print("\nProbing: $c");
    try {
      final res = await http.get(Uri.parse(c));
      print("Status: ${res.statusCode}");
      if (res.statusCode == 200) {
        print("Body: ${res.body}");
      } else {
        print("Error: ${res.reasonPhrase}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }
}
