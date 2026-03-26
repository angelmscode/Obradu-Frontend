class MaterialInventario {
  final int id;
  final String nombre;
  final int cantidad;

  MaterialInventario({
    required this.id,
    required this.nombre,
    required this.cantidad,
  });

  factory MaterialInventario.fromJson(Map<String, dynamic> json) {
    return MaterialInventario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'Sin Nombre',
      cantidad: (json['stock_total'] ?? 0).toInt(), 
    );
  }
}