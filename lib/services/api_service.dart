import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:obradu/models/material_inventario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/obra.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', data['access_token']);

        debugPrint('¡Login correcto! Token guardado.');
        return true;
      } else {
        debugPrint('Error en las credenciales: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error de conexión con el servidor: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> obtenerPerfil(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error obteniendo perfil: $e');
      return null;
    }
  }

  Future<List<Obra>> getObras() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        debugPrint('No hay token, el usuario no está logueado');
        return []; 
      }

      final response = await http.get(
        Uri.parse('$baseUrl/obras/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Obra.fromJson(item)).toList();
      } else {
        debugPrint('Error al descargar obras. Código: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de conexión en getObras: $e');
      return [];
    }
  }

  Future<List<dynamic>> getTareasObra(int obraId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/asistencias/obra/$obraId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        debugPrint('Error al cargar tareas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de red: $e');
      return [];
    }
  }Future<bool> crearTarea(int obraId, String descripcion, {int? empleadoId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final perfil = await obtenerPerfil(token);
      
      final int usuarioId = empleadoId ?? (perfil?['id'] ?? 1);

      final response = await http.post(
        Uri.parse('$baseUrl/asistencias/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'obra_id': obraId,
          'empleado_id': usuarioId,
          'tipo': 'TAREA',
          'descripcion': descripcion,
          'fecha': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('Error al crear tarea: $e');
      return false;
    }
  }
  Future<bool> completarTarea(int tareaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/asistencias/$tareaId/completar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al completar tarea: $e');
      return false;
    }
  }

  Future<bool> deshacerTarea(int tareaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/asistencias/$tareaId/deshacer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al deshacer tarea: $e');
      return false;
    }
  }

  Future<List<dynamic>> getEmpleadosObra(int obraId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/obras/$obraId/empleados'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      debugPrint('Error al cargar empleados: $e');
      return [];
    }
  }
  

  //Vehiculos 

  // Obtener toda la flota
  Future<List<dynamic>> getVehiculos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/vehiculos/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      debugPrint('Error al cargar vehículos: $e');
      return [];
    }
  }

  // Reservar un vehículo
  Future<bool> reservarVehiculo(int vehiculoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final perfil = await obtenerPerfil(token);
      final int usuarioId = perfil?['id'] ?? 1;

      final response = await http.post(
        Uri.parse('$baseUrl/vehiculos/reservar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehiculo_id': vehiculoId,
          'empleado_id': usuarioId,
          'fecha_reserva': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('Error al reservar vehículo: $e');
      return false;
    }
  }

  // Devolver un vehículo
  Future<bool> devolverVehiculo(int vehiculoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/vehiculos/$vehiculoId/devolver'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al devolver vehículo: $e');
      return false;
    }
  }

  // Enviar al taller
  Future<bool> enviarVehiculoTaller(int vehiculoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/vehiculos/$vehiculoId/taller'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al enviar al taller: $e');
      return false;
    }
  }

  // Marcar como reparado 
  Future<bool> recuperarVehiculoTaller(int vehiculoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/vehiculos/$vehiculoId/reparado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al recuperar del taller: $e');
      return false;
    }
  }

  // Obtener toda la plantilla
  Future<List<dynamic>> getEmpleados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      debugPrint('Error al cargar empleados: $e');
      return [];
    }
  }

  // Dar de alta a un empleado 
  Future<bool> crearEmpleado(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('Error al crear empleado: $e');
      return false;
    }
  }

  // Despedir/Borrar empleado
  Future<bool> eliminarEmpleado(int empleadoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/usuarios/$empleadoId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al eliminar empleado: $e');
      return false;
    }
  }
  // Asignar un empleado a una obra 
  Future<bool> asignarEmpleadoAObra(int obraId, int empleadoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/obras/$obraId/empleados'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'empleado_id': empleadoId,
          'fecha_asignacion': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error al asignar empleado: $e');
      return false;
    }
  }

// MÉTODOS DE INVENTARIO

  // Obtener todos los materiales
  Future<List<MaterialInventario>> getMateriales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/materiales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => MaterialInventario.fromJson(item)).toList();
      } else {
        debugPrint('Error al obtener materiales: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de conexión en getMateriales: $e');
      return [];
    }
  }

  // Crear un material nuevo
  Future<bool> crearMaterial(Map<String, dynamic> datos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/materiales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(datos),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error de conexión en crearMaterial: $e');
      return false;
    }
  }

  // Eliminar un material
  Future<bool> eliminarMaterial(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/materiales/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error de conexión en eliminarMaterial: $e');
      return false;
    }
  }

// ASIGNAR MATERIAL A OBRA
  Future<bool> asignarMaterialAObra(int obraId, int materialId, int cantidad) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/obras/$obraId/materiales'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'material_id': materialId,
          'cantidad_asignada': cantidad,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Material asignado y stock restado correctamente');
        return true;
      } else {
        debugPrint('Error al asignar material: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error de conexión en asignarMaterialAObra: $e');
      return false;
    }
  }
 
 Future<List<dynamic>> getMaterialesObra(int obraId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/obras/$obraId/materiales'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        debugPrint('Error al obtener materiales de la obra. Código: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de conexión en getMaterialesObra: $e');
      return [];
    }
  }
Future<Map<String, dynamic>?> getEstadisticasPanel() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); 

    if (token == null) throw Exception('No hay token de sesión');

    final response = await http.get(
      Uri.parse('$baseUrl/obras/estadisticas/panel-jefe'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); 
    } else {
      throw Exception('Error al cargar estadísticas: ${response.body}');
    }
  }
  
}
