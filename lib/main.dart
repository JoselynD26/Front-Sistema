import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'utils/error_handler.dart';
import 'utils/mouse_tracker_fix.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/aula_screen.dart';
import 'screens/escritorio_screen.dart';
import 'screens/carrera_screen.dart';
import 'screens/sede_screen.dart';
import 'screens/detalle_sede_screen.dart';
import 'screens/docente_screen.dart';
import 'screens/sala_screen.dart';
import 'screens/horario_screen.dart';
import 'screens/horarios_pdf_screen.dart';
import 'screens/croquis_screen.dart';

void main() {
  ErrorHandler.initialize();
  runApp(const GestionAcademicaApp());
}

class GestionAcademicaApp extends StatelessWidget {
  const GestionAcademicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MouseTrackerFix(
        child: MaterialApp(
      title: 'Sistema de Gestión Académica',
      theme: _buildWebTheme(),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
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

          case '/horariosPdf': // ✅ nueva ruta para ver/subir PDFs
            return MaterialPageRoute(
              builder: (_) => const HorariosPdfScreen(),
            );

          case '/croquis': // ✅ nueva ruta para croquis
            return MaterialPageRoute(
              builder: (_) => const CroquisScreen(),
            );

          default:
            return null;
        }
      },
        ),
      ),
    );
  }

  ThemeData _buildWebTheme() {
    // Colores Yavirac: Naranja, Azul, Blanco
    const yaviracOrange = Color(0xFFFF6B35);
    const yaviracBlue = Color(0xFF1E3A8A);
    const yaviracLightBlue = Color(0xFF3B82F6);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: yaviracBlue,
        primary: yaviracBlue,
        secondary: yaviracOrange,
        brightness: Brightness.light,
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: yaviracBlue,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(12),
        color: Colors.white,
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yaviracOrange,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Data table theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(yaviracBlue.withOpacity(0.1)),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return yaviracOrange.withOpacity(0.1);
          }
          return null;
        }),
        columnSpacing: 32,
        horizontalMargin: 24,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: yaviracBlue,
          fontSize: 16,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: yaviracOrange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}