class Usuario {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'Sin Nombre',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? 'Sin Email',
      rol: json['rol'] ?? 'EMPLEADO', 
    );
  }
}