class Tarea {
  final int id;
  final int empleadoId;
  final int obraId;
  final String tipo; // TAREA o ASISTENCIA
  final String? descripcion;
  final String fecha;
  final bool completada;
  final String? horaEntrada;
  final String? horaSalida;

  Tarea({
    required this.id,
    required this.empleadoId,
    required this.obraId,
    required this.tipo,
    this.descripcion,
    required this.fecha,
    required this.completada,
    this.horaEntrada,
    this.horaSalida,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      empleadoId: json['empleado_id'] is int ? json['empleado_id'] : int.tryParse(json['empleado_id'].toString()) ?? 0,
      obraId: json['obra_id'] is int ? json['obra_id'] : int.tryParse(json['obra_id'].toString()) ?? 0,
      tipo: json['tipo'] ?? 'TAREA',
      descripcion: json['descripcion'],
      fecha: json['fecha'] ?? '',
      completada: json['completada'] == true || json['completada'] == 1,
      horaEntrada: json['hora_entrada'],
      horaSalida: json['hora_salida'],
    );
  }
}