// #region Imports
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/obradu_drawer.dart';
// #endregion

// #region Widget Principal
class PanelJefeScreen extends StatefulWidget {
  const PanelJefeScreen({super.key});

  @override
  State<PanelJefeScreen> createState() => _PanelJefeScreenState();
}
// #endregion

class _PanelJefeScreenState extends State<PanelJefeScreen> {
  
  // #region Variables de Estado
  String _nombre = "Cargando...";
  String _rol = "";
  Future<Map<String, dynamic>?> _estadisticasFuture = Future.value(null);
  // #endregion

  // #region Ciclo de Vida y Carga de Datos
  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _estadisticasFuture = ApiService().getEstadisticasPanel();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Jefe";
      _rol = prefs.getString('rol') ?? "JEFE";
    });
  }

  Future<void> _recargarPanel() async {
    setState(() {
      _estadisticasFuture = ApiService().getEstadisticasPanel();
    });
  }
  // #endregion

  // #region Constructor de Interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 240, 240),
      appBar: AppBar(
        title: const Text(
          'Panel Principal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol),
      body: RefreshIndicator(
        onRefresh: _recargarPanel,
        color: AppColors.primary,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _estadisticasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar las estadísticas.\nArrastra hacia abajo para reintentar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;

            // Datos principales
            final obrasActivas = data['obras_activas']?.toString() ?? '0';
            final personalTotal = data['personal_total']?.toString() ?? '0';
            final vehiculosUso = data['vehiculos_uso']?.toString() ?? '0';

            // Datos para los subtítulos 
            final vehiculosDisponibles =
                data['vehiculos_disponibles']?.toString() ?? '0';
            final vehiculosTaller = data['vehiculos_taller']?.toString() ?? '0';
            final personalOcupado = data['personal_ocupado']?.toString() ?? '0';
            final obrasFinalizadas =
                data['obras_finalizadas']?.toString() ?? '0';

            final progresoObras =
                data['progreso_obras'] as List<dynamic>? ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $_nombre!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aquí tienes el resumen de tu empresa hoy.',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),

                  // TARJETA OBRAS ACTIVAS
                  _crearTarjetaEstadistica(
                    titulo: 'Obras Activas',
                    valor: obrasActivas,
                    icono: Icons.business_center,
                    colorFondoIcono: Colors.blue.shade500,
                    widgetInferior: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$obrasFinalizadas finalizadas históricamente',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TARJETA PERSONAL
                  _crearTarjetaEstadistica(
                    titulo: 'Personal Total',
                    valor: personalTotal,
                    icono: Icons.people_alt,
                    colorFondoIcono: Colors.indigo.shade400,
                    widgetInferior: Row(
                      children: [
                        const Icon(
                          Icons.engineering,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$personalOcupado asignados a obras',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TARJETA VEHÍCULOS
                  _crearTarjetaEstadistica(
                    titulo: 'Vehículos en Uso',
                    valor: vehiculosUso,
                    icono: Icons.local_shipping,
                    colorFondoIcono: AppColors.primary,
                    widgetInferior: Row(
                      children: [
                        // Disponibles en verde
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$vehiculosDisponibles libres',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Taller en rojo
                        const Icon(Icons.build, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$vehiculosTaller en taller',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Progreso de Obras',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: progresoObras.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No hay obras activas en este momento.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : Column(
                            children: progresoObras.map((obra) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _simuladorBarraGrafico(
                                  obra['nombre']?.toString() ??
                                      'Obra desconocida',
                                  (obra['progreso'] as num?)?.toDouble() ?? 0.0,
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  // #endregion

  // #region Widgets Auxiliares
  // WIDGET REUTILIZABLE PARA LAS TARJETAS 
  Widget _crearTarjetaEstadistica({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color colorFondoIcono,
    Widget? widgetInferior, 
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (widgetInferior != null) ...[
                const SizedBox(height: 8),
                widgetInferior,
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorFondoIcono,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // WIDGET PARA LA BARRA DE PROGRESO
  Widget _simuladorBarraGrafico(String nombre, double progreso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                nombre,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(progreso * 100).toInt()}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progreso,
          backgroundColor: Colors.grey.shade200,
          color: AppColors.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
  // #endregion
}