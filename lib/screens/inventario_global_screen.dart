import 'package:flutter/material.dart';
import 'package:obradu/models/material_inventario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart'; 
import '../widgets/obradu_drawer.dart';
import '../services/api_service.dart';

class InventarioGlobalScreen extends StatefulWidget {
  const InventarioGlobalScreen({super.key});

  @override
  State<InventarioGlobalScreen> createState() => _InventarioGlobalScreenState();
}

class _InventarioGlobalScreenState extends State<InventarioGlobalScreen> {
  List<MaterialInventario> _materiales = [];
  bool _cargando = true;
  
  String _nombre = "Cargando...";
  String _rol = "JEFE";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarInventario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Usuario";
      _rol = prefs.getString('rol') ?? "JEFE";
    });
  }

  Future<void> _cargarInventario() async {
    setState(() => _cargando = true);
    try {
      final inventarioSrv = await ApiService().getMateriales();
      if (mounted) {
        setState(() {
          _materiales = inventarioSrv;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // FUNCIÓN PARA AÑADIR MATERIAL NUEVO
  void _mostrarDialogoNuevoMaterial() {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Añadir al Almacén', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText:   'Nombre del material',
                hintText: 'Ej: Cable de cobre, Cemento...',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad inicial',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Cancelar')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white
            ),
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext); 
              setState(() => _cargando = true);

              final exito = await ApiService().crearMaterial({
                'nombre': nombreCtrl.text,
                'stock_total': int.tryParse(cantidadCtrl.text) ?? 0,
              });

              if (exito) {
                _cargarInventario(); 
                messenger.showSnackBar(
                  const SnackBar(content: Text('Material guardado con éxito'), backgroundColor: Colors.green)
                );
              } else {
                setState(() => _cargando = false);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Error al guardar material'), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _borrarMaterial(int id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Material?'),
        content: Text('¿Seguro que quieres borrar $nombre del inventario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _cargando = true);
      final exito = await ApiService().eliminarMaterial(id);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material eliminado'), backgroundColor: Colors.green));
          _cargarInventario();
        } else {
          setState(() => _cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Inventario Global', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol), 
      floatingActionButton: _rol == 'JEFE' ? FloatingActionButton(
        onPressed: _mostrarDialogoNuevoMaterial, 
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      body: RefreshIndicator(
        onRefresh: _cargarInventario,
        color: AppColors.primary,
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _materiales.isEmpty 
              ? const Center(child: Text("No hay materiales en el inventario")) 
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _materiales.length,
                  itemBuilder: (context, index) {
                    final mat = _materiales[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.5),
                          child: const Icon(Icons.construction, color: AppColors.primary),
                        ),
                        title: Text(mat.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Cantidad disponible: ${mat.cantidad}'),
                        trailing: _rol == 'JEFE' ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _borrarMaterial(mat.id, mat.nombre),
                        ) : null,
                      ),
                    );
                  },
                ),
      ),
    );
  }
}