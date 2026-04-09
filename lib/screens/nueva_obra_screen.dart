import 'package:flutter/material.dart';
import 'package:obradu/services/api_service.dart';
import '../theme/app_colors.dart';

// #region Widget Principal
class NuevaObraScreen extends StatefulWidget {
  const NuevaObraScreen({super.key});

  @override
  State<NuevaObraScreen> createState() => _NuevaObraScreenState();
}
// #endregion

class _NuevaObraScreenState extends State<NuevaObraScreen> {
  
  // #region Variables de Estado y Controladores
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  // #endregion

  // #region Ciclo de Vida
  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }
  // #endregion

  // #region Lógica y Acciones
  void _guardarObra() async {
    if (_formKey.currentState!.validate()) {
      final String nombreObra = _nombreController.text;
      final String ubicacionObra = _ubicacionController.text;
      
      bool exito = await ApiService().crearObra(nombreObra, ubicacionObra);

      if (!mounted) return; 

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obra "$nombreObra" creada con éxito'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la obra. Verifica tu conexión o los datos.'),
            backgroundColor: Colors.red,
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
        title: const Text('Nueva Obra', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos de la Obra',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la obra *',
                  hintText: 'Ej. Residencial Las Lomas',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de la obra es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación / Dirección',
                  hintText: 'Ej. Calle Mayor 12, Madrid',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _guardarObra,
                  child: const Text(
                    'CREAR OBRA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // #endregion
}