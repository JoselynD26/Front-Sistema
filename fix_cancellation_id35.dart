import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = "http://localhost:8000";
  final sedeId = 1;
  final fecha = "2026-01-02"; // Friday
  final targetHorarioId = 35; // Confirmed via diagnose logs

  print("--- FIXING CANCELLATION FOR ID $targetHorarioId ---");
  
  final urlPost = Uri.parse("$baseUrl/horarios/cancelados/");
  final body = jsonEncode({
    "horario_id": targetHorarioId,
    "fecha": fecha,
    "motivo": "Manual Fix - ID 35 Conflict",
    "estado": "cancelado",
    "sede_id": sedeId
  });
  
  try {
    print("Posting cancellation...");
    final resPost = await http.post(urlPost,
      headers: {"Content-Type": "application/json"},
      body: body
    );
    
    print("POST Response Code: ${resPost.statusCode}");
    print("POST Response Body: ${resPost.body}");
    
    if (resPost.statusCode >= 200 && resPost.statusCode < 300) {
      print("✅ SUCCESS: Cancellation created for ID 35.");
    } else {
      print("❌ FAILURE: Could not create cancellation.");
    }
  } catch (e) {
    print("Error creating cancellation: $e");
  }
}
