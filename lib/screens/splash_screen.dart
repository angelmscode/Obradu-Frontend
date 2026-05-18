import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'panel_jefe_screen.dart';

// #region Widget Principal
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
// #endregion

class _SplashScreenState extends State<SplashScreen> {
  
  // #region Ciclo de Vida del estado
  @override
  void initState() {
    super.initState();
    _comprobarLogin();
  }
  // #endregion

  // #region Lógica de Enrutamiento (Roles)
  void _comprobarLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (!mounted) return;

    if (token == null) {
      _navegarA(const LoginScreen());
      return;
    }

    // Validar el token contra el servidor antes de navegar
    final perfil = await ApiService.obtenerPerfil(token);

    if (!mounted) return;

    if (perfil != null) {
      // Token válido — actualizamos el rol por si cambió y navegamos
      final String rol = perfil['rol'] ?? prefs.getString('rol') ?? 'EMPLEADO';
      await prefs.setString('rol', rol);

      if (!mounted) return;

      _navegarA(rol == 'JEFE' ? const PanelJefeScreen() : const HomeScreen());
    } else {
      // Token caducado o inválido — limpiamos y mandamos al login
      await prefs.remove('token');
      await prefs.remove('rol');
      await prefs.remove('nombre');
      await prefs.remove('usuario_id');

      if (!mounted) return;
      _navegarA(const LoginScreen());
    }
  }

  void _navegarA(Widget pantalla) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }
  // #endregion

  // #region Interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logoObraDu.png', height: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
  // #endregion
}