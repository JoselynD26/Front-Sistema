import 'package:flutter/material.dart';
import 'croquis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Menú Principal")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.class_),
            title: Text("Aulas"),
            subtitle: Text("Ver listado de aulas"),
            onTap: () => Navigator.pushNamed(context, '/aulas'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.chair),
            title: Text("Escritorios"),
            subtitle: Text("Filtrar escritorios por jornada"),
            onTap: () => Navigator.pushNamed(context, '/escritorios'),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.blue),
            title: Text("Carreras"),
            subtitle: Text("Ver listado de carreras"),
            onTap: () => Navigator.pushNamed(context, '/carreras'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.map),
            title: Text("Croquis"),
            subtitle: Text("Gestionar croquis de aulas y salas"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CroquisScreen(sedeId: 1, rol: 'admin')),
            ),
          ),
          Divider(),
        ],
      ),
    );
  }
}