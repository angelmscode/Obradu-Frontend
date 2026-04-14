import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/obradu_drawer.dart';
import '../services/api_service.dart';
import '../models/vehiculo.dart';

// #region Widget Principal
class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}
// #endregion

class _VehiculosScreenState extends State<VehiculosScreen> {
  // #region Variables de Estado
  String _nombre = "";
  String _rol = "";
  int? _miId;
  List<Vehiculo> _vehiculos = [];
  bool _cargando = true;
  // #endregion

  // #region Ciclo de Vida
  @override
  void initState() {
    super.initState();
    _cargarDatosYVehiculos();
  }
  // #endregion

  // #region Lógica y Peticiones API
  Future<void> _cargarDatosYVehiculos() async {
    setState(() => _cargando = true);
    final prefs = await SharedPreferences.getInstance();
    _nombre = prefs.getString('nombre') ?? "Usuario";
    _rol = prefs.getString('rol') ?? "EMPLEADO";
    _miId = prefs.getInt('usuario_id');
    await _cargarVehiculos();
  }

  Future<void> _cargarVehiculos() async {
    final vehiculosServidor = await ApiService().getVehiculos();
    if (mounted) {
      setState(() {
        _vehiculos = vehiculosServidor;
        _cargando = false;
      });
    }
  }

  Future<void> _accionVehiculo(
    Future<bool> Function(int) accionApi,
    int id,
    String mensajeExito,
  ) async {
    setState(() => _cargando = true);
    final exito = await accionApi(id);

    if (exito) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeExito),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _cargarVehiculos();
    } else {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al realizar la acción'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  // #endregion

  // #region Constructor de Interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mi Flota',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.background,
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _cargarVehiculos,
              color: AppColors.primary,
              child: _vehiculos.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No hay vehículos registrados en la flota.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _vehiculos.length,
                      itemBuilder: (context, index) {
                        return _crearTarjetaVehiculo(_vehiculos[index]);
                      },
                    ),
            ),
    );
  }
  // #endregion

  // #region Widgets Auxiliares
  Widget _crearTarjetaVehiculo(Vehiculo vehiculo) {
    final int id = vehiculo.id;
    final String matricula = vehiculo.matricula;
    final String modelo = vehiculo.modelo;
    final String estado = vehiculo.estado;

    final bool loTengoYo = (vehiculo.usuarioId == _miId && _miId != null);

    Color colorBorde = AppColors.cardBorder;
    Color colorFondoIcono = Colors.grey.withValues(alpha: 0.2);
    Color colorIcono = Colors.grey;
    IconData icono = Icons.local_shipping;

    List<Widget> botones = [];

    if (estado == 'DISPONIBLE') {
      colorBorde = AppColors.success;
      colorFondoIcono = AppColors.success.withValues(alpha: 0.1);
      colorIcono = AppColors.success;

      botones.add(
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _accionVehiculo(
            ApiService().reservarVehiculo,
            id,
            'Vehículo reservado',
          ),
          child: const Text('Reservar'),
        ),
      );

      if (_rol == 'JEFE') {
        botones.add(
          IconButton(
            icon: const Icon(Icons.build, color: AppColors.error),
            tooltip: 'Enviar al Taller',
            onPressed: () => _accionVehiculo(
              ApiService().enviarVehiculoTaller,
              id,
              'Enviado al taller',
            ),
          ),
        );
      }
    } else if (estado == 'EN_USO') {
      colorBorde = AppColors.warning;
      colorFondoIcono = AppColors.warning.withValues(alpha: 0.1);
      colorIcono = AppColors.warning;

      if (loTengoYo || _rol == 'JEFE') {
        botones.add(
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
            onPressed: () => _accionVehiculo(
              ApiService().devolverVehiculo,
              id,
              'Vehículo devuelto',
            ),
            child: const Text('Devolver'),
          ),
        );
      } else {
        botones.add(
          const Text(
            "Ocupado",
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    } else if (estado == 'TALLER') {
      colorBorde = AppColors.error;
      colorFondoIcono = AppColors.error.withValues(alpha: 0.1);
      colorIcono = AppColors.error;
      icono = Icons.car_repair;

      if (_rol == 'JEFE') {
        botones.add(
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Marcar Reparado'),
            onPressed: () => _accionVehiculo(
              ApiService().recuperarVehiculoTaller,
              id,
              'Vehículo reparado',
            ),
          ),
        );
      } else {
        botones.add(
          const Text(
            'En reparación',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorBorde, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorFondoIcono,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: colorIcono, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          matricula,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (estado == 'EN_USO')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      vehiculo.asignadoA != null ? Icons.person : Icons.info_outline, 
                      size: 16, 
                      color: colorIcono
                    ), 
                    const SizedBox(width: 8),
                    Text(
                      loTengoYo
                          ? "LO TIENES TÚ"
                          : (vehiculo.asignadoA != null)
                              ? "EN USO POR: ${vehiculo.asignadoA!.toUpperCase()}"
                              : "VEHÍCULO EN USO",
                      style: TextStyle(
                        color: colorIcono,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: botones),
          ],
        ),
      ),
    );
  }
  // #endregion
}