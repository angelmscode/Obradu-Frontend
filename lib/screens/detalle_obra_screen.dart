// #region Imports
import 'package:flutter/material.dart';
import 'package:obradu/models/material_obra.dart';
import 'package:obradu/models/obra.dart';
import 'package:obradu/models/tarea.dart';
import 'package:obradu/models/usuario.dart';
import 'package:obradu/widgets/dialogo_asignar_material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
// #endregion

// #region Definición del Widget
class DetalleObraScreen extends StatefulWidget {
  final Obra obra;
  final String rol;

  const DetalleObraScreen({super.key, required this.obra, required this.rol});

  @override
  State<DetalleObraScreen> createState() => _DetalleObraScreenState();
}
// #endregion

class _DetalleObraScreenState extends State<DetalleObraScreen> {
  // #region Variables de Estado
  List<Tarea> _tareas = [];
  bool _cargando = true;

  List<Usuario> _empleados = [];
  int? _empleadoSeleccionado;

  final TextEditingController _nuevaTareaController = TextEditingController();
  // #endregion

  // #region Ciclo de Vida
  @override
  void initState() {
    super.initState();
    _cargarTareas();
    _cargarEmpleados();
  }

  @override
  void dispose() {
    _nuevaTareaController.dispose();
    super.dispose();
  }
  // #endregion

  // #region Lógica de Datos y API

  Future<void> _cargarTareas() async {
    setState(() => _cargando = true);
    final tareasServidor = await ApiService().getTareasObra(widget.obra.id);

    if (!mounted) return;

    List<Tarea> tareasOrdenadas = List.from(tareasServidor);

    tareasOrdenadas.sort((a, b) {
      int valorA = a.completada ? 1 : 0;
      int valorB = b.completada ? 1 : 0;
      return valorA.compareTo(valorB);
    });

    setState(() {
      _tareas = tareasOrdenadas.where((t) => t.tipo == 'TAREA').toList();
      _cargando = false;
    });
  }

  Future<void> _cargarEmpleados() async {
    final empleados = await ApiService().getEmpleadosObra(widget.obra.id);
    if (!mounted) return;

    setState(() {
      _empleados = empleados;
      if (widget.rol == 'JEFE' && _empleados.isNotEmpty) {
        _empleadoSeleccionado = _empleados[0].id;
      }
    });
  }

  void _guardarNuevaTarea() async {
    final texto = _nuevaTareaController.text.trim();
    if (texto.isEmpty) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    setState(() => _cargando = true);

    final exito = await ApiService().crearTarea(
      widget.obra.id,
      texto,
      empleadoId: widget.rol == 'JEFE' ? _empleadoSeleccionado : null,
    );

    if (exito) {
      _nuevaTareaController.clear();
      await _cargarTareas();
    } else {
      if (mounted) setState(() => _cargando = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la tarea'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completarTareaServer(int tareaId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _cargando = true);
    final exito = await ApiService().completarTarea(tareaId);

    if (exito) {
      await _cargarTareas();
    } else {
      if (mounted) setState(() => _cargando = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Error al completar la tarea.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _reasignarTareaServer(int tareaId, int nuevoEmpleadoId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final exito = await ApiService().reasignarTarea(tareaId, nuevoEmpleadoId);

    if (exito) {
      await _cargarTareas();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Tarea reasignada con éxito')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Error al reasignar la tarea')),
      );
    }
  }

  Future<void> _deshacerTareaServer(int tareaId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _cargando = true);
    final exito = await ApiService().deshacerTarea(tareaId);

    if (exito) {
      await _cargarTareas();
    } else {
      if (mounted) setState(() => _cargando = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Error al deshacer la tarea'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  // #endregion

  // #region Diálogos

  Future<void> _mostrarDialogoConsumirMaterial(int tareaId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final materialesObra = await ApiService().getMaterialesObra(widget.obra.id);
    final materialesDisponibles = materialesObra
        .where((m) => m.cantidadAsignada > 0)
        .toList();

    if (!mounted) return;

    if (materialesDisponibles.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('No hay materiales con stock en esta obra.'),
        ),
      );
      return;
    }

    int? materialSeleccionado;
    final TextEditingController cantController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gastar Material'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: materialSeleccionado,
                hint: const Text("Selecciona el material"),
                items: {for (var m in materialesDisponibles) m.id: m}.values
                    .map((m) {
                      return DropdownMenuItem<int>(
                        value: m.id,
                        child: Text(
                          "${m.nombre} (Stock: ${m.cantidadAsignada})",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => materialSeleccionado = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a gastar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (materialSeleccionado == null || cantController.text.isEmpty) {
                return;
              }

              int cant = int.tryParse(cantController.text) ?? 0;
              if (cant <= 0) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              bool exito = await ApiService().consumirMaterialObra(
                widget.obra.id,
                materialSeleccionado!,
                cant,
              );

              navigator.pop();

              if (exito) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Material descontado de la obra con éxito'),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Error al gastar material (revisa el stock)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmar Uso'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoMaterialesObra(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inventario en Obra'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: FutureBuilder<List<MaterialObra>>(
              future: ApiService().getMaterialesObra(widget.obra.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar los materiales.'),
                  );
                }

                final materiales = snapshot.data ?? [];

                if (materiales.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay materiales asignados a esta obra.'),
                  );
                }

                return ListView.builder(
                  itemCount: materiales.length,
                  itemBuilder: (context, index) {
                    final mat = materiales[index];

                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(
                          Icons.handyman,
                          color: Colors.orange,
                        ),
                        title: Text(
                          mat.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '${mat.cantidadAsignada} uds',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoNuevaTarea() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Añadir nueva tarea',
                style: TextStyle(color: AppColors.primaryDark),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nuevaTareaController,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Instalar cableado eléctrico',
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (widget.rol == 'JEFE' && _empleados.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Asignar a:',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      initialValue:
                          _empleados.any(
                            (emp) => emp.id == _empleadoSeleccionado,
                          )
                          ? _empleadoSeleccionado
                          : (_empleados.isNotEmpty
                                ? _empleados.first.id
                                : null),
                      isExpanded: true,
                      items: _empleados.map((Usuario emp) {
                        return DropdownMenuItem<int>(
                          value: emp.id,
                          child: Text(
                            '${emp.nombre} ${emp.apellidos}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (int? nuevoValor) {
                        setStateDialog(() {
                          _empleadoSeleccionado = nuevoValor;
                        });
                        setState(() {
                          _empleadoSeleccionado = nuevoValor;
                        });
                      },
                    ),
                  ],
                  if (widget.rol == 'JEFE' && _empleados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'No hay empleados asignados a esta obra',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _nuevaTareaController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  onPressed: _guardarNuevaTarea,
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // #endregion

  // #region Pantalla Principal
  @override
  Widget build(BuildContext context) {
    double progreso = widget.obra.progreso;

    if (!_cargando && _tareas.isNotEmpty) {
      int tareasCompletadas = _tareas.where((tarea) => tarea.completada).length;

      progreso = tareasCompletadas / _tareas.length;
    } else if (!_cargando && _tareas.isEmpty) {
      progreso = 0.0;
    }

    final bool esJefe = widget.rol == 'JEFE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.obra.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 216, 218, 219),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.obra.direccion,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'En progreso',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              '${(progreso * 100).toInt()}% Completado',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progreso,
                          backgroundColor: AppColors.cardBorder,
                          color: AppColors.primary,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        if (esJefe) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.local_shipping),
                              label: const Text('Enviar Material a Obra'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: AppColors.background,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final resultado = await showDialog(
                                  context: context,
                                  builder: (context) => DialogoAsignarMaterial(
                                    obraId: widget.obra.id,
                                    apiService: ApiService(),
                                  ),
                                );

                                if (resultado == true) {
                                  debugPrint('Material enviado correctamente');
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _mostrarDialogoMaterialesObra(context),
                              icon: const Icon(Icons.inventory_2),
                              label: const Text('Ver Materiales de la Obra'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: AppColors.background,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tareas de hoy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Chip(
                        label: Text(esJefe ? 'Modo: JEFE' : 'Modo: EMPLEADO'),
                        backgroundColor: esJefe
                            ? AppColors.warning.withValues(alpha: 0.2)
                            : AppColors.pending.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: esJefe ? AppColors.warning : AppColors.pending,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_tareas.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay tareas registradas.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),

                  ...List.generate(
                    _tareas.length,
                    (index) => _crearTarjetaTarea(index, esJefe),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaTarea,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }
  // #endregion

  // #region Métodos y Widgets Auxiliares
  Map<String, String> _obtenerDatosEmpleado(int? empleadoId) {
    if (empleadoId == null || _empleados.isEmpty) {
      return {'nombreCompleto': 'Sin asignar', 'iniciales': '??'};
    }

    try {
      final empleado = _empleados.firstWhere((emp) => emp.id == empleadoId);

      String nombre = empleado.nombre;
      String apellidos = empleado.apellidos;

      String inicialNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
      String inicialApellido = apellidos.isNotEmpty
          ? apellidos[0].toUpperCase()
          : '';

      return {
        'nombreCompleto': '$nombre $apellidos',
        'iniciales': '$inicialNombre$inicialApellido',
      };
    } catch (e) {
      return {'nombreCompleto': 'Empleado no encontrado', 'iniciales': '??'};
    }
  }

  Widget _crearTarjetaTarea(int index, bool esJefe) {
    final Tarea tarea = _tareas[index];
    final int tareaId = tarea.id;
    final titulo = tarea.descripcion ?? 'Sin título';
    final bool estaCompletada = tarea.completada;

    Color colorFondo = estaCompletada
        ? AppColors.background
        : AppColors.cardBackground;
    Color colorIcono = estaCompletada
        ? AppColors.success
        : AppColors.textSecondary;
    IconData icono = estaCompletada
        ? Icons.check_circle
        : Icons.radio_button_unchecked;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorFondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icono, color: colorIcono),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: estaCompletada
                          ? TextDecoration.lineThrough
                          : null,
                      color: estaCompletada
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final datosEmp = _obtenerDatosEmpleado(tarea.empleadoId);
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              datosEmp['iniciales']!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Asignado a: ${datosEmp['nombreCompleto']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            if (!estaCompletada)
              IconButton(
                icon: const Icon(Icons.handyman, color: Colors.orange),
                tooltip: 'Gastar Material',
                onPressed: () => _mostrarDialogoConsumirMaterial(tareaId),
              ),

            if (widget.rol == 'JEFE' && !estaCompletada)
              IconButton(
                icon: const Icon(
                  Icons.person_add_alt_1,
                  color: AppColors.primary,
                ),
                tooltip: 'Reasignar Tarea',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      int? seleccionado;
                      return AlertDialog(
                        title: const Text('Reasignar Tarea'),
                        content: DropdownButtonFormField<int>(
                          items: {for (var emp in _empleados) emp.id: emp}
                              .values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text('${e.nombre} ${e.apellidos}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => seleccionado = val,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar operario',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (seleccionado != null) {
                                final navigator = Navigator.of(context);
                                _reasignarTareaServer(tareaId, seleccionado!);
                                navigator.pop();
                              }
                            },
                            child: const Text('Asignar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

            const SizedBox(width: 8),
            estaCompletada
                ? IconButton(
                    icon: const Icon(
                      Icons.undo,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _deshacerTareaServer(tareaId),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: esJefe
                          ? AppColors.success
                          : AppColors.primaryDark,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _completarTareaServer(tareaId),
                    child: Text(
                      esJefe ? 'Aprobar' : 'Terminar',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // #endregion
}
