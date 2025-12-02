class Escritorio {
  final int id;
  final String codigo;
  final String estado;
  final String jornada;
  final int salaId;
  final int carreraId;
  final int? docenteId;
  final int? croquisId;

  Escritorio({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.jornada,
    required this.salaId,
    required this.carreraId,
    this.docenteId,
    this.croquisId,
  });

  factory Escritorio.fromJson(Map<String, dynamic> json) {
    return Escritorio(
      id: json['id'],
      codigo: json['codigo'],
      estado: json['estado'],
      jornada: json['jornada'],
      salaId: json['sala_id'],
      carreraId: json['carrera_id'],
      docenteId: json['docente_id'],
      croquisId: json['croquis_id'],
    );
  }
}