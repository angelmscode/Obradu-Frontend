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
  int? _miId;

  Future<List<Obra>>? _obrasFuture;
  final ValueNotifier<Duration> _tiempoEfectivoNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<Duration> _tiempoPausaNotifier = ValueNotifier(
    Duration.zero,
  );
  // #endregion

  // #region Ciclo de Vida y Carga de Datos
  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  @override
  void dispose() {
    _tiempoEfectivoNotifier.dispose(); 
    _tiempoPausaNotifier.dispose(); 
    super.dispose();
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
      _miId = prefs.getInt('usuario_id');
    });
  }

  void _actualizarTiemposEnPantalla(Duration efectivo, Duration pausa) {
    _tiempoEfectivoNotifier.value = efectivo;
    _tiempoPausaNotifier.value = pausa;
  }
  // #endregion

  // #region Constructor de Interfaz
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
              FichajeCard(
                usuarioId: _miId!,
                onTiempoActualizado: _actualizarTiemposEnPantalla,
              ),

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
                tiempoEfectivoNotifier: _tiempoEfectivoNotifier,
                tiempoPausaNotifier: _tiempoPausaNotifier,
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
  final ValueNotifier<Duration> tiempoEfectivoNotifier;
  final ValueNotifier<Duration> tiempoPausaNotifier;

  const ResumenJornadaCard({
    super.key,
    required this.tiempoEfectivoNotifier,
    required this.tiempoPausaNotifier,
  });

  String formatear(Duration d) {
    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    return "${dosDigitos(d.inHours)}:${dosDigitos(d.inMinutes.remainder(60))}:${dosDigitos(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumen de Jornada",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            AnimatedBuilder(
              animation: Listenable.merge([
                tiempoEfectivoNotifier,
                tiempoPausaNotifier,
              ]),
              builder: (context, child) {
                final efectivo = tiempoEfectivoNotifier.value;
                final pausa = tiempoPausaNotifier.value;

                final int balanceSegundos = efectivo.inSeconds - 28800;
                final bool esPositivo = balanceSegundos >= 0;
                final Duration balanceAbsoluto = Duration(
                  seconds: balanceSegundos.abs(),
                );

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _itemTiempo(
                          "Efectivo",
                          formatear(efectivo),
                          Icons.timer,
                          AppColors.primary,
                        ),
                        _itemTiempo(
                          "Pausa",
                          formatear(pausa),
                          Icons.restaurant,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: esPositivo
                            ? Colors.green.shade50
                            : Colors.red.shade50,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTiempo(String label, String valor, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              valor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
