class Vehiculo {
  final int id;
  final String matricula;
  final String modelo;
  final String estado;
  final int? usuarioId;
  final String? asignadoA;

  Vehiculo({
    required this.id,
    required this.matricula,
    required this.modelo,
    required this.estado,
    this.usuarioId,
    this.asignadoA,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      matricula: json['matricula'] ?? 'Sin Matrícula',
      modelo: json['modelo'] ?? 'Modelo Desconocido',
      estado: json['estado'] ?? 'DISPONIBLE',
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id']
          : int.tryParse(json['usuario_id']?.toString() ?? ''),
      asignadoA: json['nombre_usuario'],
    );
  }
}