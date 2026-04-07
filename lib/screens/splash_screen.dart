import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
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
    final String? rol = prefs.getString('rol'); 

    if (!mounted) return;

    if (token != null) {
      if (rol == 'JEFE') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PanelJefeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // Si no hay llave, a logearse
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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