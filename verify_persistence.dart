import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = "http://localhost:8000";
  final sedeId = 1;
  final datesToCheck = ["2026-01-01", "2026-01-02", "2026-01-03"];
  
  print("--- AUDITING CANCELLATIONS ---");

  for (var date in datesToCheck) {
    final url = Uri.parse("$baseUrl/horarios/cancelados/?sede_id=$sedeId&fecha=$date");
    print("Checking $date: $url");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        print("  -> Count: ${data.length}");
        for (var c in data) {
           print("     * Item: $c");
        }
      } else {
        print("  -> Error: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("  -> Exception: $e");
    }
  }
}
