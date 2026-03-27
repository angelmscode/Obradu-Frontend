import 'package:flutter/material.dart';
import 'package:obradu/widgets/dialogo_asignar_material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class DetalleObraScreen extends StatefulWidget {
  final Map<String, dynamic> obra;
  final String rol;

  const DetalleObraScreen({super.key, required this.obra, required this.rol});

  @override
  State<DetalleObraScreen> createState() => _DetalleObraScreenState();
}

class _DetalleObraScreenState extends State<DetalleObraScreen> {
  List<dynamic> _tareas = [];
  bool _cargando = true;

  List<dynamic> _empleados = [];
  int? _empleadoSeleccionado;

  final TextEditingController _nuevaTareaController = TextEditingController();

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

  Future<void> _cargarTareas() async {
    setState(() => _cargando = true);
    final tareasServidor = await ApiService().getTareasObra(widget.obra['id']);
    
    List<dynamic> tareasOrdenadas = List.from(tareasServidor);

    tareasOrdenadas.sort((a, b) {
      bool estaCompletadaA = a['completada'] == true || a['completada'] == 1; 
      bool estaCompletadaB = b['completada'] == true || b['completada'] == 1;

      int valorA = estaCompletadaA ? 1 : 0;
      int valorB = estaCompletadaB ? 1 : 0;

      return valorA.compareTo(valorB);
    });

    setState(() {
      _tareas = tareasOrdenadas;
      _cargando = false;
    });
  }

  // Función para cargar los empleados
  Future<void> _cargarEmpleados() async {
    final empleados = await ApiService().getEmpleadosObra(widget.obra['id']);
    if (mounted) {
      setState(() {
        _empleados = empleados;
        if (widget.rol == 'JEFE' && _empleados.isNotEmpty) {
          _empleadoSeleccionado = _empleados[0]['id'];
        }
      });
    }
  }

  void _guardarNuevaTarea() async {
    final texto = _nuevaTareaController.text.trim();
    if (texto.isEmpty) return;

    Navigator.pop(context);
    setState(() => _cargando = true);

    final exito = await ApiService().crearTarea(
      widget.obra['id'],
      texto,
      empleadoId: widget.rol == 'JEFE' ? _empleadoSeleccionado : null,
    );

    if (exito) {
      _nuevaTareaController.clear();
      await _cargarTareas();
    } else {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la tarea'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completarTareaServer(int tareaId) async {
    setState(() => _cargando = true);
    final exito = await ApiService().completarTarea(tareaId);
    if (exito) {
      await _cargarTareas();
    } else {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al completar la tarea.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deshacerTareaServer(int tareaId) async {
    setState(() => _cargando = true);
    final exito = await ApiService().deshacerTarea(tareaId);
    if (exito) {
      await _cargarTareas();
    } else {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al deshacer la tarea'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
            child: FutureBuilder<List<dynamic>>(
              future: ApiService().getMaterialesObra(widget.obra['id']),
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

                    final nombreMaterial =
                        mat['nombre'] ??
                        mat['material']?['nombre'] ??
                        'Material desconocido';
                    
                    final cantidad =
                        mat['cantidad_asignada'] ??
                        mat['pivot']?['cantidad_asignada'] ??
                        mat['cantidad'] ??
                        0;

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
                          nombreMaterial,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '$cantidad uds',
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
                      value: _empleadoSeleccionado,
                      isExpanded: true,
                      items: _empleados.map((emp) {
                        return DropdownMenuItem<int>(
                          value: emp['id'],
                          child: Text(
                            '${emp['nombre']} ${emp['apellidos']}',
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

 @override
  Widget build(BuildContext context) {
    double progreso = widget.obra['progreso'] != null 
        ? (widget.obra['progreso'] as num).toDouble() 
        : 0.0;
    
    if (!_cargando && _tareas.isNotEmpty) {
      int tareasCompletadas = _tareas.where((tarea) {
        return tarea['completada'] == true || tarea['completada'] == 1;
      }).length;
      
      progreso = tareasCompletadas / _tareas.length;
    } else if (!_cargando && _tareas.isEmpty) {
      progreso = 0.0; 
    }

    final bool esJefe = widget.rol == 'JEFE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.obra['nombre'],
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
                                widget.obra['ubicacion'],
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
                              obraId: widget.obra['id'],
                              apiService: ApiService(),
                            ),
                          );

                          if (resultado == true) {
                            debugPrint('Material enviado correctamente');
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoMaterialesObra(context),
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

  Map<String, String> _obtenerDatosEmpleado(int? empleadoId) {
    if (empleadoId == null || _empleados.isEmpty) {
      return {'nombreCompleto': 'Sin asignar', 'iniciales': '??'};
    }

    final empleado = _empleados.firstWhere(
      (emp) => emp['id'] == empleadoId,
      orElse: () => null,
    );

    if (empleado == null) {
      return {'nombreCompleto': 'Empleado no encontrado', 'iniciales': '??'};
    }

    String nombre = empleado['nombre'] ?? '';
    String apellidos = empleado['apellidos'] ?? '';

    String inicialNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    String inicialApellido = apellidos.isNotEmpty
        ? apellidos[0].toUpperCase()
        : '';

    return {
      'nombreCompleto': '$nombre $apellidos',
      'iniciales': '$inicialNombre$inicialApellido',
    };
  }

  Widget _crearTarjetaTarea(int index, bool esJefe) {
    final tarea = _tareas[index];

    final int tareaId = tarea['id'];
    final titulo = tarea['descripcion'] ?? 'Sin título';
    final bool estaCompletada = tarea['completada'] == true;

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
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          leading: Icon(icono, color: colorIcono),
          title: Text(
            titulo,
            style: TextStyle(
              decoration: estaCompletada ? TextDecoration.lineThrough : null,
              color: estaCompletada
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),

          subtitle: Builder(
            builder: (context) {
              final datosEmp = _obtenerDatosEmpleado(tarea['empleado_id']);
              return Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      datosEmp['iniciales']!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Asignado a: ${datosEmp['nombreCompleto']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          trailing: estaCompletada
              ? IconButton(
                  icon: const Icon(Icons.undo, color: AppColors.textSecondary),
                  tooltip: 'Deshacer tarea',
                  onPressed: () => _deshacerTareaServer(tareaId),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esJefe
                        ? AppColors.success
                        : AppColors.primaryDark,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _completarTareaServer(tareaId),
                  child: Text(esJefe ? 'Aprobar' : 'Terminar'),
                ),
        ),
      ),
    );
  }
}
