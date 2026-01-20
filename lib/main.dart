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
    // DeepL Inspired Palette
    const primaryColor = Color(0xFF0070C9); // DeepL Primary Blue
    const secondaryColor = Color(0xFF0F2B46); // DeepL Dark Blue
    const tertiaryColor = Color(0xFFFF6B35); // Vibrant Orange (Accent)
    const backgroundColor = Color(0xFFF5F7F8); // DeepL Background
    const surfaceColor = Colors.white;
    const errorColor = Color(0xFFC34331);
    const warningColor = Color(0xFF622700);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor, // New Orange Accent
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: secondaryColor, // Dark blue text on white app bar
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: secondaryColor,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Slightly softer
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.all(12),
        color: surfaceColor,
        clipBehavior: Clip.antiAlias,
      ),
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Modern, clean radius
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: Colors.grey.shade400,
      ),
      // Floating Action Button - BLUE per user request ("ponle azul al agregar")
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor, 
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: surfaceColor,
        elevation: 8,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    // Adapted DeepL Palette for Dark Mode
    const primaryColor = Color(0xFF3B82F6); // Lighter blue for better visibility in dark
    const secondaryColor = Color(0xFF0F2B46); // DeepL Dark Blue used as background base or accent
    const backgroundColor = Color(0xFF0F172A); // Keeping Slate 900 for proper contrast
    const surfaceColor = Color(0xFF1E293B); // Slate 800
    const textColor = Colors.white;
    // Note: We might want to use the DeepL Dark Blue (0xFF0F2B46) as the surface or background
    // but Slate 900 is usually better for "Dark Mode". 
    // Let's try to incorporate the DeepL feel by ensuring Primary is compatible.
    
    // If the user wants STRICT DeepL colors also in Dark Mode, we can adjust. 
    // For now, I'll keep the slate base but ensure the blues align with expectations.
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: const Color(0xFF60A5FA), 
        surface: surfaceColor,
        background: backgroundColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundColor,
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
          borderRadius: BorderRadius.circular(12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIconColor: Colors.grey.shade400,
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: surfaceColor,
        elevation: 8,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: TextStyle(fontSize: 14, color: Colors.grey.shade300, height: 1.5),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
