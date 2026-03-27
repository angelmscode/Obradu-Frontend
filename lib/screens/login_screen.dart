import 'package:flutter/material.dart';
import 'package:obradu/screens/panel_jefe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  // Controladores para leer lo que el usuario escribe
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  void _hacerLogin() async {
    setState(() {
      _isLoading = true; // Carga empezada
    });

    bool exito = await _apiService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (exito) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token'); // Rescatar el token

        if (token != null) {
          final perfil = await ApiService.obtenerPerfil(token);

          if (perfil != null) {
            await prefs.setString('rol', perfil['rol'] ?? 'EMPLEADO'); 
            await prefs.setString('nombre', perfil['nombre'] ?? 'Usuario');
          }
        }
      } catch (e) {
        debugPrint("Error al guardar el perfil: $e");
      }

      setState(() {
        _isLoading = false; // Carga finalizada
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido a ObraDu!'), backgroundColor: Colors.green),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PanelJefeScreen()),
      );
      
    } else {
      setState(() {
        _isLoading = false; // Carga finalizada si falla
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Credenciales incorrectas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logoObraDu.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                'OBRADU',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              // Campo de Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true, 
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _hacerLogin,
                        child: const Text(
                          'ENTRAR',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}