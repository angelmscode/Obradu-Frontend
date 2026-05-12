class Usuario {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final String rol;
  final String nombreEmpresa;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.rol,
    required this.nombreEmpresa,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'Sin Nombre',
      apellidos: json['apellidos'] ?? '',
      email: json['email'] ?? 'Sin Email',
      rol: json['rol'] ?? 'EMPLEADO', 
      nombreEmpresa: json['empresa'] != null 
          ? json['empresa']['nombre'] 
          : 'Sin Empresa',
    );
  }
}