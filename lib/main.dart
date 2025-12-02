import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/aula_screen.dart';
import 'screens/escritorio_screen.dart';
import 'screens/carrera_screen.dart';
import 'screens/sede_screen.dart';
import 'screens/detalle_sede_screen.dart';
import 'screens/docente_screen.dart';   // ✅ nuevo import
import 'screens/sala_screen.dart';      // ✅ nuevo import

void main() {
  runApp(const GestionAcademicaApp());
}

class GestionAcademicaApp extends StatelessWidget {
  const GestionAcademicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión Académica',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), // arranca en login
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/sedes':
            return MaterialPageRoute(builder: (_) => const SedeScreen());

          case '/detalleSede':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DetalleSedeScreen(
                idSede: args['idSede'],
                nombre: args['nombre'],
              ),
            );

          case '/aulas':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AulasScreen(idSede: args['idSede']),
            );

          case '/carreras':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CarrerasScreen(idSede: args['idSede']),
            );

          case '/escritorios':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => EscritoriosScreen(idSede: args['idSede']),
            );

          case '/docentes': // ✅ nueva ruta
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DocentesScreen(idSede: args['idSede']),
            );

          case '/salas': // ✅ nueva ruta para salas
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SalasScreen(idSede: args['idSede']),
            );

          default:
            return null;
        }
      },
    );
  }
}