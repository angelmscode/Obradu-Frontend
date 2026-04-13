import 'package:flutter/material.dart';
import 'package:obradu/widgets/fichar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/obradu_drawer.dart';
import 'detalle_obra_screen.dart';
import 'nueva_obra_screen.dart';
import '../services/api_service.dart';
import '../models/obra.dart';

// #region Widget Principal
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
// #endregion

class _HomeScreenState extends State<HomeScreen> {
  // #region Variables de Estado
  String _nombre = "Cargando...";
  String _rol = "";

  Future<List<Obra>>? _obrasFuture;
  Duration _tiempoEfectivo = Duration.zero;
  Duration _tiempoPausa = Duration.zero;
  // #endregion

  // #region Ciclo de Vida y Carga de Datos
  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  Future<void> _inicializarPantalla() async {
    await _cargarDatosUsuario();

    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        _obrasFuture = ApiService().getObras();
      });
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Usuario";
      _rol = prefs.getString('rol') ?? "EMPLEADO";
    });
  }

  void _actualizarTiemposEnPantalla(Duration efectivo, Duration pausa) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _tiempoEfectivo = efectivo;
          _tiempoPausa = pausa;
        });
      }
    });
  }
  // #endregion

  // #region Constructor de Interfaz (Build)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Panel de Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.background,
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _obrasFuture = ApiService().getObras();
          });
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aquí tienes el resumen de tu jornada y obras.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // TARJETA DE FICHAJE
              FichajeCard(onTiempoActualizado: _actualizarTiemposEnPantalla),

              const SizedBox(height: 32),

              // LISTA DE OBRAS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tus Obras Activas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (_rol == 'JEFE')
                    Chip(
                      label: const Text(
                        'MODO JEFE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: AppColors.warning),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Obra>>(
                future: _obrasFuture,
                builder: (context, snapshot) {
                  if (_obrasFuture == null ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error de conexión: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.business_center_outlined,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aún no hay obras registradas.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final obras = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: obras.length,
                    itemBuilder: (context, index) {
                      return _crearTarjetaObra(obras[index]);
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // RESUMEN DE JORNADA
              ResumenJornadaCard(
                tiempoEfectivo: _tiempoEfectivo,
                tiempoPausa: _tiempoPausa,
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: _rol == 'JEFE'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NuevaObraScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _obrasFuture = ApiService().getObras();
                  });
                });
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              icon: const Icon(Icons.add_business),
              label: const Text(
                'NUEVA OBRA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _crearTarjetaObra(Obra obra) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleObraScreen(obra: obra, rol: _rol),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icono de la obra
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.construction,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obra.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            obra.direccion,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
// #endregion


class ResumenJornadaCard extends StatelessWidget {
  final Duration tiempoEfectivo;
  final Duration tiempoPausa;
  final Duration jornadaStandard = const Duration(hours: 8);

  const ResumenJornadaCard({
    super.key,
    required this.tiempoEfectivo,
    required this.tiempoPausa,
  });

  @override
  Widget build(BuildContext context) {
    final int difSegundos =
        tiempoEfectivo.inSeconds - jornadaStandard.inSeconds;
    final bool esPositivo = difSegundos >= 0;
    final Duration balanceAbsoluto = Duration(seconds: difSegundos.abs());

    String formatear(Duration d) {
      if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
      return "${d.inMinutes}m";
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Balance Diario",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.work_outline, color: AppColors.primary),
                        const SizedBox(height: 8),
                        const Text(
                          "Trabajo Efectivo",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          formatear(tiempoEfectivo),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.free_breakfast_outlined,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(height: 8),
                        const Text("Descanso", style: TextStyle(fontSize: 12)),
                        Text(
                          formatear(tiempoPausa),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: esPositivo ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(
                  color: esPositivo
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    esPositivo
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: esPositivo
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      esPositivo
                          ? "Jornada completada (+${formatear(balanceAbsoluto)} extra)"
                          : "Por cumplir: ${formatear(balanceAbsoluto)}",
                      style: TextStyle(
                        color: esPositivo
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
