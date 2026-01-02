import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sede_screen.dart';
import 'screens/detalle_sede_screen.dart';
import 'screens/aula_screen.dart';
import 'screens/escritorio_screen.dart';
import 'screens/carrera_screen.dart';
import 'screens/docente_screen.dart';
import 'screens/sala_screen.dart';
import 'screens/horario_screen.dart';
import 'screens/horarios_pdf_screen.dart';
import 'screens/croquis_screen.dart';
import 'screens/docente_croquis_screen.dart';
import 'utils/theme_manager.dart';

void main() {
  runApp(const GestionAcademicaApp());
}

class GestionAcademicaApp extends StatelessWidget {
  const GestionAcademicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager(),
      builder: (context, _) {
        return MaterialApp(
          title: 'Sistema de Gestión Académica',
          debugShowCheckedModeBanner: false,
          theme: _buildWebTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: ThemeManager().themeMode,
          home: const LoginScreen(),

          /// 🔹 RUTAS CENTRALIZADAS
          onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );

          case '/sedes':
            return MaterialPageRoute(
              builder: (_) => const SedeScreen(),
            );

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

          case '/docentes':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DocentesScreen(idSede: args['idSede']),
            );

          case '/salas':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SalasScreen(idSede: args['idSede']),
            );

          case '/horariosPdf':
            return MaterialPageRoute(
              builder: (_) => const HorariosPdfScreen(),
            );

          // ❌ NO HAY RUTA /croquis AQUÍ
          // El croquis se abre desde DetalleSedeScreen (admin)
          // y DocenteCroquisScreen se abre directo para el docente

          default:
            return null;
        }
          }
        );
      },
    );
  }

  /// 🔹 THEME ORIGINAL (NO TOCADO)
  ThemeData _buildWebTheme() {
    const primaryColor = Color(0xFF2563EB);
    const secondaryColor = Color(0xFFF97316);
    const backgroundColor = Color(0xFFF8FAFC);
    const surfaceColor = Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: Color(0xFF1E293B),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF64748B)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.all(12),
        color: surfaceColor,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: Colors.grey.shade400,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
    );
  }
  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF3B82F6); // Lighter blue for dark mode
    const secondaryColor = Color(0xFFF97316);
    const backgroundColor = Color(0xFF0F172A); // Slate 900
    const surfaceColor = Color(0xFF1E293B); // Slate 800
    const textColor = Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // dividerColor: Colors.grey.shade700,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade700),
        ),
        margin: const EdgeInsets.all(12),
        color: surfaceColor,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155), // Slate 700
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIconColor: Colors.grey.shade400,
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceColor,
        elevation: 8,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: TextStyle(fontSize: 14, color: Colors.grey.shade300, height: 1.5),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
