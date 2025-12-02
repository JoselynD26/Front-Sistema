import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'sede_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  final _apiService = ApiService();
  bool cargando = false;
  String? error;

  Future<void> _login() async {
    setState(() {
      cargando = true;
      error = null;
    });

    final success = await _apiService.login(
      _correoController.text.trim(),
      _claveController.text.trim(),
    );

    setState(() {
      cargando = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SedeScreen()),
      );
    } else {
      setState(() {
        error = "Credenciales inválidas. Intenta nuevamente.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: "Correo",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _claveController,
              decoration: const InputDecoration(
                labelText: "Clave",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (cargando) const CircularProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cargando ? null : _login,
              child: const Text("Ingresar"),
            ),
          ],
        ),
      ),
    );
  }
}