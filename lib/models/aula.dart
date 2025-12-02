class Aula {
  final int id;
  final String nombre;
  final String numero;
  final int capacidad;
  final String descripcion;
  final int idSede;

  Aula({
    required this.id,
    required this.nombre,
    required this.numero,
    required this.capacidad,
    required this.descripcion,
    required this.idSede,
  });

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      numero: json['numero'] ?? '',
      capacidad: json['capacidad'] ?? 0,
      descripcion: json['descripcion'] ?? '',
      idSede: json['id_sede'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "numero": numero,
      "capacidad": capacidad,
      "descripcion": descripcion,
      "id_sede": idSede,
    };
  }
}