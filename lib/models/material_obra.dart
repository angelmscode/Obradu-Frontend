class MaterialObra {
  final int id;
  final String nombre;
  int cantidadAsignada;

  MaterialObra({
    required this.id,
    required this.nombre,
    required this.cantidadAsignada,
  });

  factory MaterialObra.fromJson(Map<String, dynamic> json) {
    return MaterialObra(
      id: json['id'] ?? 0,
      nombre: json['material_nombre'] ?? json['nombre'] ?? 'Desconocido',
      cantidadAsignada:
          json['cantidad_asignada'] ?? json['pivot']?['cantidad_asignada'] ?? 0,
          
    );
  }
}
