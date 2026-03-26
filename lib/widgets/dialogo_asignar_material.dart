import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/material_inventario.dart'; 

class DialogoAsignarMaterial extends StatefulWidget {
  final int obraId;
  final ApiService apiService;

  const DialogoAsignarMaterial({super.key, required this.obraId, required this.apiService});

  @override
  State<DialogoAsignarMaterial> createState() => _DialogoAsignarMaterialState();
}

class _DialogoAsignarMaterialState extends State<DialogoAsignarMaterial> {
  List<MaterialInventario> _materiales = [];
  MaterialInventario? _materialSeleccionado;
  final TextEditingController _cantidadController = TextEditingController();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMateriales();
  }

  Future<void> _cargarMateriales() async {
    final materiales = await widget.apiService.getMateriales();
    
    if (!mounted) return;

    setState(() {
      _materiales = materiales.where((m) => m.cantidad > 0).toList();
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_materiales.isEmpty) {
      return AlertDialog(
        title: const Text('Sin stock'),
        content: const Text('No hay materiales disponibles en el almacén para enviar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), 
            child: const Text('Cerrar')
          )
        ],
      );
    }

    return AlertDialog(
      title: const Text('Mandar Material a Obra'),
      content: SizedBox(
        width: 400, 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            DropdownButtonFormField<MaterialInventario>(
              decoration: const InputDecoration(labelText: 'Selecciona un material'),
              initialValue: _materialSeleccionado,
              isExpanded: true, 
              items: _materiales.map((mat) {
                return DropdownMenuItem<MaterialInventario>(
                  value: mat,
                  child: Row(
                    children: [
                      Expanded( 
                        child: Text(
                          mat.nombre,
                          overflow: TextOverflow.ellipsis, 
                        ),
                      ),
                      Text(
                        ' (${mat.cantidad})',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _materialSeleccionado = val;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad a enviar',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_materialSeleccionado == null || _cantidadController.text.isEmpty) return;

            int cantidad = int.tryParse(_cantidadController.text) ?? 0;
            
            if (cantidad <= 0 || cantidad > _materialSeleccionado!.cantidad) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cantidad no válida o superior al stock disponible')),
              );
              return;
            }

            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            bool exito = await widget.apiService.asignarMaterialAObra(
              widget.obraId,
              _materialSeleccionado!.id,
              cantidad,
            );

            if (!mounted) return;

            if (exito) {
              navigator.pop(true); 
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('¡Material enviado a la obra!')),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Error al enviar el material')),
              );
            }
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}