import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/obradu_drawer.dart';
import '../services/api_service.dart';
import '../models/usuario.dart';

// #region Widget Principal
class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}
// #endregion

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  // #region Variables de Estado
  String _nombre = "";
  String _rol = "";
  List<Usuario> _empleados = [];
  bool _cargando = true;

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _rolSeleccionado = 'EMPLEADO';
  // #endregion

  // #region Ciclo de Vida y Carga de Datos
  @override
  void initState() {
    super.initState();
    _cargarDatosYEmpleados();
  }

  Future<void> _cargarDatosYEmpleados() async {
    setState(() => _cargando = true);
    final prefs = await SharedPreferences.getInstance();
    _nombre = prefs.getString('nombre') ?? "Usuario";
    _rol = prefs.getString('rol') ?? "EMPLEADO";
    await _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    final empleadosSrv = await ApiService().getEmpleados();
    if (mounted) {
      setState(() {
        _empleados = empleadosSrv;
        _cargando = false;
      });
    }
  }
  // #endregion

  // #region Acciones (Eliminar / Nuevo / Asignar)
  Future<void> _eliminar(int id, String nombreEmpleado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Despedir empleado?'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a $nombreEmpleado del sistema? Esta acción no se puede deshacer.',
        ),
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
      final exito = await ApiService().eliminarEmpleado(id);
      if (exito) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado eliminado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        await _cargarEmpleados();
      } else {
        setState(() => _cargando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _mostrarDialogoNuevoEmpleado() {
    _nombreCtrl.clear();
    _apellidosCtrl.clear();
    _emailCtrl.clear();
    _passCtrl.clear();
    _rolSeleccionado = 'EMPLEADO';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextStateful, setStateDialog) {
          return AlertDialog(
            title: const Text('Nuevo Empleado'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _apellidosCtrl,
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña temporal',
                      ),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _rolSeleccionado,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: 'EMPLEADO',
                          child: Text('Peón / Empleado'),
                        ),
                        DropdownMenuItem(
                          value: 'JEFE',
                          child: Text('Jefe de Obra'),
                        ),
                      ],
                      onChanged: (val) {
                        setStateDialog(() => _rolSeleccionado = val!);
                        setState(() => _rolSeleccionado = val!);
                      },
                    ),
                  ],
                ),
              ),
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
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext);
                    setState(() => _cargando = true);

                    final exito = await ApiService().crearEmpleado({
                      "nombre": _nombreCtrl.text,
                      "apellidos": _apellidosCtrl.text,
                      "email": _emailCtrl.text,
                      "password": _passCtrl.text,
                      "rol": _rolSeleccionado,
                    });

                    if (!mounted) return;

                    if (exito) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Empleado registrado'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _cargarEmpleados();
                    } else {
                      setState(() => _cargando = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al registrar'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDetallesEmpleado(Usuario emp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                '${emp.nombre} ${emp.apellidos}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                emp.rol,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo electrónico'),
                subtitle: Text(emp.email),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('ID de Empleado'),
                subtitle: Text('#${emp.id}'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoAsignarObra(int empleadoId, String nombreCompleto) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final obras = await ApiService().getObras();

    if (!mounted) return;
    Navigator.pop(context);

    if (obras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay obras disponibles')));
      return;
    }

    int? obraSeleccionadaId = obras[0].id;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setStateDialog) {
            return AlertDialog(
              title: Text(
                'Asignar a $nombreCompleto',
                style: const TextStyle(fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecciona la obra:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    initialValue: obraSeleccionadaId,
                    isExpanded: true,
                    items: obras.map((obra) {
                      return DropdownMenuItem<int>(
                        value: obra.id,
                        child: Text(
                          obra.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (int? nuevoValor) {
                      setStateDialog(() {
                        obraSeleccionadaId = nuevoValor;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (obraSeleccionadaId != null) {
                      Navigator.pop(dialogContext);

                      final exito = await ApiService().asignarEmpleadoAObra(
                        obraSeleccionadaId!,
                        empleadoId,
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            exito
                                ? 'Asignado correctamente'
                                : 'Error al asignar',
                          ),
                          backgroundColor: exito ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Asignar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // #endregion

  // #region Constructor de Interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mi Equipo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.background,
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol),
      floatingActionButton: _rol == 'JEFE'
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoNuevoEmpleado,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Añadir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _cargarEmpleados,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80,
                ),
                itemCount: _empleados.length,
                itemBuilder: (context, index) {
                  final emp = _empleados[index];
                  final esJefe = emp.rol == 'JEFE';

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _mostrarDetallesEmpleado(emp),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: esJefe
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.grey.shade200,
                          child: Icon(
                            esJefe ? Icons.engineering : Icons.person,
                            color: esJefe
                                ? AppColors.primary
                                : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          '${emp.nombre} ${emp.apellidos}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              emp.email,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: esJefe
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                emp.rol,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: esJefe
                                      ? AppColors.primary
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: _rol == 'JEFE'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Asignar a Obra',
                                    icon: const Icon(
                                      Icons.add_business_outlined,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      final nombreCompleto =
                                          '${emp.nombre} ${emp.apellidos}';
                                      _mostrarDialogoAsignarObra(
                                        emp.id,
                                        nombreCompleto,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar empleado',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () =>
                                        _eliminar(emp.id, emp.nombre),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // #endregion
}
