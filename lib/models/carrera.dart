class Carrera {
  final int id;
  final String nombre;

  Carrera({
    required this.id,
    required this.nombre,
  });

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
    };
  }
}