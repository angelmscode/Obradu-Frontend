class Obra {
  final int id;
  final String nombre;
  final String direccion;
  final String fechaInicio;
  final String? fechaFin; 
  final double? presupuesto; 
  final double progreso;
  final int jefeId;

  Obra({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.fechaInicio,
    this.fechaFin,
    this.presupuesto,
    required this.progreso,
    required this.jefeId,
  });

  factory Obra.fromJson(Map<String, dynamic> json) {
    return Obra(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      presupuesto: json['presupuesto'] != null ? double.parse(json['presupuesto'].toString()) : null,
      progreso: json['progreso'] != null ? double.parse(json['progreso'].toString()) : 0.0,
      jefeId: json['jefe_id'],
    );
  }
}