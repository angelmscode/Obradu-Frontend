import 'package:flutter/material.dart';
import 'package:obradu/models/material_inventario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/obradu_drawer.dart';
import '../services/api_service.dart';

// #region Widget Principal
class InventarioGlobalScreen extends StatefulWidget {
  const InventarioGlobalScreen({super.key});

  @override
  State<InventarioGlobalScreen> createState() => _InventarioGlobalScreenState();
}
// #endregion

class _InventarioGlobalScreenState extends State<InventarioGlobalScreen> {
  // #region Variables de Estado
  List<MaterialInventario> _materiales = [];
  bool _cargando = true;
  bool _ordenAlfabetico = false;

  String _nombre = "Cargando...";
  String _rol = "JEFE";
  // #endregion

  // #region Ciclo de Vida y Carga de Datos
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
  // #endregion

  // #region Acciones (Añadir / Borrar)
  // FUNCIÓN PARA AÑADIR MATERIAL NUEVO
  void _mostrarDialogoNuevoMaterial() {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Añadir al Almacén',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del material',
                hintText: 'Añade (kg), (L), (m) ...',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad inicial'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
                  const SnackBar(
                    content: Text('Material guardado con éxito'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                setState(() => _cargando = false);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Error al guardar material'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAnadirStock(int id, String nombre) {
    final TextEditingController cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Añadir stock a $nombre'),
        content: TextField(
          controller: cantidadCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cantidad a sumar',
            hintText: 'Ej: 10',
            prefixIcon: Icon(Icons.add_box),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext), // Usamos dialogContext aquí
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              int? cantidad = int.tryParse(cantidadCtrl.text);
              if (cantidad != null && cantidad > 0) {
                final messenger = ScaffoldMessenger.of(context);

                Navigator.pop(dialogContext);

                bool exito = await ApiService().anadirStockMaterial(
                  id,
                  cantidad,
                );

                if (!mounted) return;

                if (exito) {
                  _cargarInventario();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '+$cantidad añadido correctamente a $nombre',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Error al conectar con el servidor'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Añadir', style: TextStyle(color: Colors.white)),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarInventario();
        } else {
          setState(() => _cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  // #endregion

  // #region Constructor de Interfaz
  @override
  Widget build(BuildContext context) {
    List<MaterialInventario> materialesAMostrar = List.from(_materiales);

    if (_ordenAlfabetico) {
      materialesAMostrar.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );
    } else {
      materialesAMostrar.sort(
        (a, b) => a.id.compareTo(b.id),
      ); // Vuelve al orden por ID
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Inventario Global'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort_by_alpha,
              color: _ordenAlfabetico ? Colors.white : Colors.white54,
            ),
            tooltip: 'Ordenar por nombre',
            onPressed: () {
              setState(() {
                _ordenAlfabetico = !_ordenAlfabetico;
              });
            },
          ),
        ],
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol),
      floatingActionButton: _rol == 'JEFE'
          ? FloatingActionButton(
              onPressed: _mostrarDialogoNuevoMaterial,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _cargarInventario,
        color: AppColors.primary,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : materialesAMostrar
                  .isEmpty //
            ? const Center(child: Text("No hay materiales en el inventario"))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount:
                    materialesAMostrar.length, 
                itemBuilder: (context, index) {
                  final mat =
                      materialesAMostrar[index];  
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.5,
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        mat.nombre,                        
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text('Cantidad disponible: ${mat.cantidad}'),
                      trailing: _rol == 'JEFE'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Añadir unidades',
                                  onPressed: () => _mostrarDialogoAnadirStock(
                                    mat.id,
                                    mat.nombre,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Borrar material',
                                  onPressed: () =>
                                      _borrarMaterial(mat.id, mat.nombre),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
  // #endregion

  // #endregion
}
