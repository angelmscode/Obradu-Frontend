import 'package:flutter/material.dart';
import 'package:obradu/screens/nueva_obra_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/obradu_drawer.dart';
import 'detalle_obra_screen.dart';
import '../services/api_service.dart';
import '../models/obra.dart';

// #region Widget Principal
class ObrasScreen extends StatefulWidget {
  const ObrasScreen({super.key});

  @override
  State<ObrasScreen> createState() => _ObrasScreenState();
}
// #endregion

class _ObrasScreenState extends State<ObrasScreen> {
  
  // #region Variables de Estado
  String _nombre = "";
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

  // #region Constructor de Interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Obras', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.background,
      ),
      drawer: ObraDuDrawer(nombre: _nombre, rol: _rol),

      floatingActionButton: _rol == 'JEFE'
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async { 
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NuevaObraScreen()),
                );

                if (resultado == true) {
                  setState(() {
                    _obrasFuture = ApiService().getObras();
                  });
                }
              },
            )
          : null,

      body: FutureBuilder<List<Obra>>(
        future: _obrasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error de conexión: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay obras registradas.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final obras = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: obras.length,
            itemBuilder: (context, index) {
              return _crearTarjetaObra(obras[index]);
            },
          );
        },
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleObraScreen(obra: obra, rol: _rol),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obra.nombre,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              const SizedBox(height: 16),
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
