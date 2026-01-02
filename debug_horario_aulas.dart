
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final fecha = "2026-01-02";
  final sedeId = 1;
  final url = Uri.parse("http://localhost:8000/profesor/horario-aulas?sede_id=$sedeId&fecha=$fecha");
  
  print("Probing: $url");
  try {
    final res = await http.get(url);
    print("Status: ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Body: ${res.body}");
      final data = jsonDecode(res.body);
      print("Items: ${data.length}");
    } else {
      print("Error: ${res.reasonPhrase}");
    }
  } catch (e) {
    print("Exception: $e");
  }
}
