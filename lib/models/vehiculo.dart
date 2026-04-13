class Vehiculo {
  final int id;
  final String matricula;
  final String modelo;
  final String estado;

  Vehiculo({
    required this.id,
    required this.matricula,
    required this.modelo,
    required this.estado,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      matricula: json['matricula'] ?? 'Sin Matrícula',  
      modelo: json['modelo'] ?? 'Modelo Desconocido',
      estado: json['estado'] ?? 'DISPONIBLE',
    );
  }
}