
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final int horarioId = 35;
  final String fecha = "2026-01-02";
  final int sedeId = 1;
  final String motivo = "Fixing ghost record manually via script";

  final url = Uri.parse("http://localhost:8000/horarios/cancelados/");
  
  final Map<String, dynamic> data = {
    "horario_id": horarioId,
    "fecha": fecha,
    "motivo": motivo,
    "estado": "cancelado",
    "sede_id": sedeId
  };

  print("Sending correction request...");
  print("URL: $url");
  print("Body: ${jsonEncode(data)}");

  try {
    final res = await http.post(
      url, 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data)
    );

    print("Response Status: ${res.statusCode}");
    print("Response Body: ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      print("SUCCESS! Record recreated correctly with sede_id.");
    } else {
      print("FAILED.");
    }
  } catch (e) {
    print("Exception: $e");
  }
}
