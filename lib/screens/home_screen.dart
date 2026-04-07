import 'package:flutter/material.dart';
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
  
  late Future<List<Obra>> _obrasFuture;
  // #endregion

  // #region Ciclo de Vida y Carga de Datos
  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _obrasFuture = ApiService().getObras();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Usuario";
      _rol = prefs.getString('rol') ?? "EMPLEADO";
    });
  }
  // #endregion

  // #region Constructor de Interfaz (Build)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel de Control', style: TextStyle(fontWeight: FontWeight.bold)),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aquí tienes el resumen de tus obras hoy.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tus Obras Activas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  if (_rol == 'JEFE')
                    Chip(
                      label: const Text('MODO JEFE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: AppColors.warning),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Obra>>(
                future: _obrasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error de conexión: ${snapshot.error}', 
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        )
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.business_center_outlined, size: 60, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text('Aún no hay obras registradas.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
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
                MaterialPageRoute(builder: (context) => const NuevaObraScreen()),
              ).then((_) {
                setState(() {
                  _obrasFuture = ApiService().getObras();
                });
              });
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            icon: const Icon(Icons.add_business),
            label: const Text('NUEVA OBRA', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        : null, 
    );
  }
  // #endregion

  // #region Widgets Auxiliares
  Widget _crearTarjetaObra(Obra obra) {
    double progreso = obra.progreso; 
      
    String estado = progreso >= 1.0 ? 'Finalizada' : 'En progreso';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleObraScreen(
                obra: {
                  'id': obra.id, 
                  'nombre': obra.nombre,
                  'ubicacion': obra.direccion, 
                  'progreso': progreso,
                }, 
                rol: _rol
              ),
            ),
          ).then((_) {
            setState(() {
               _obrasFuture = ApiService().getObras();
            });
          });
        },
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obra.nombre,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                obra.direccion,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    estado,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  Text('${(progreso * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progreso,
                backgroundColor: AppColors.cardBorder,
                color: AppColors.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // #endregion
}