import 'package:flutter/material.dart';
import 'package:obradu/screens/login_screen.dart';
import 'package:obradu/screens/panel_jefe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/obras_screen.dart';
import '../screens/vehiculos_screen.dart';
import '../screens/empleados_screen.dart';
import '../screens/inventario_global_screen.dart';

class ObraDuDrawer extends StatelessWidget {
  final String nombre;
  final String rol;

  const ObraDuDrawer({super.key, required this.nombre, required this.rol});

  @override
  Widget build(BuildContext context) {
    const colorFondoDrawer = AppColors.drawerBackground;
    const colorTarjetaPerfil = AppColors.drawerSurface;

    return Drawer(
      backgroundColor: colorFondoDrawer,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/logoObraDu.png', height: 40),
                      const SizedBox(width: 12),
                      const Text(
                        'ObraDu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context), // Cierra el menú
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _crearOpcionMenu(
              Icons.dashboard_outlined,
              'Panel Principal',
              true,
              () {
                if (rol != 'JEFE') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PanelJefeScreen(),
                    ),
                  );
                }
              },
            ),
            _crearOpcionMenu(Icons.construction, 'Obras', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ObrasScreen()),
              );
            }),
            _crearOpcionMenu(
              Icons.local_shipping_outlined,
              'Vehículos',
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VehiculosScreen(),
                  ),
                );
              },
            ),
            _crearOpcionMenu(Icons.people_alt_outlined, 'Empleados', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmpleadosScreen(),
                ),
              );
            }),

            // Opciones exclusivas del Jefe
            if (rol == 'JEFE') ...[
              const Divider(
                color: Colors.white24,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              _crearOpcionMenu(
                Icons.inventory_2_outlined,
                'Inventario Global',
                false,
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventarioGlobalScreen(),
                    ),
                  );
                },
              ),
            ],

            const Spacer(),

            // Cerrar sesion
            _crearOpcionMenu(Icons.logout, 'Cerrar Sesión', false, () async {
              // Borramos el token de la memoria
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            }),
            // Tarjeta de Perfil del Usuario
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorTarjetaPerfil,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Avatar de prueba
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rol.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearOpcionMenu(
    IconData icono,
    String titulo,
    bool seleccionado,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: seleccionado ? const Color(0xFFFF5722) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icono,
          color: seleccionado ? Colors.white : Colors.white70,
          size: 22,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: seleccionado ? Colors.white : Colors.white70,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
