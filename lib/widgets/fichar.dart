import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/obra.dart';

class FichajeCard extends StatefulWidget {
  final int usuarioId;
  final Function(Duration efectivo, Duration pausa) onTiempoActualizado;

  const FichajeCard({
    super.key,
    required this.usuarioId,
    required this.onTiempoActualizado,
  });

  @override
  State<FichajeCard> createState() => _FichajeCardState();
}

class _FichajeCardState extends State<FichajeCard> {
  bool _enJornada = false;
  bool _enPausa = false;
  bool _procesando = false; 

  int? _asistenciaId; 
  int? _obraSeleccionadaId;
  List<Obra> _misObras = [];

  // Variables para Trabajo
  DateTime? _horaEntrada;
  Duration _duracionAcumulada = Duration.zero;
  String _tiempoDisplay = "00:00:00";

  // Variables para Pausa
  DateTime? _horaInicioPausa;
  Duration _totalPausas = Duration.zero;
  String _tiempoPausaDisplay = "00:00:00";

  Timer? _timer;

  String _k(String key) => '${key}_${widget.usuarioId}';

  @override
  void initState() {
    super.initState();
    _cargarObras();
    _cargarEstadoLocal();
  }

  Future<void> _cargarObras() async {
    final obras = await ApiService().getObras();
    if (mounted) {
      setState(() {
        _misObras = obras;
        if (_misObras.isNotEmpty) {
          _obraSeleccionadaId = _misObras.first.id;
        }
      });
    }
  }

  Future<void> _cargarEstadoLocal() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _enJornada = prefs.getBool(_k('fichaje_en_jornada')) ?? false;
      _enPausa = prefs.getBool(_k('fichaje_en_pausa')) ?? false;

      _asistenciaId = prefs.getInt(_k('fichaje_asistencia_id'));

      final strEntrada = prefs.getString(_k('fichaje_hora_entrada'));
      if (strEntrada != null) _horaEntrada = DateTime.parse(strEntrada);

      final millisAcumulada =
          prefs.getInt(_k('fichaje_duracion_acumulada')) ?? 0;
      _duracionAcumulada = Duration(milliseconds: millisAcumulada);

      final strInicioPausa = prefs.getString(_k('fichaje_hora_inicio_pausa'));
      if (strInicioPausa != null) {
        _horaInicioPausa = DateTime.parse(strInicioPausa);
      }

      final millisPausas = prefs.getInt(_k('fichaje_total_pausas')) ?? 0;
      _totalPausas = Duration(milliseconds: millisPausas);
    });

    final ultimaFecha = prefs.getString(_k('fichaje_fecha_activa'));
    final hoy = DateTime.now().toIso8601String().split('T')[0];

    if (ultimaFecha != null && ultimaFecha != hoy) {
      await _limpiarEstadoLocal();
    } else if (_enJornada) {
      _iniciarTimer();
    }
    _notificarCambios();
  }

  Future<void> _guardarEstadoLocal() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_k('fichaje_en_jornada'), _enJornada);
    await prefs.setBool(_k('fichaje_en_pausa'), _enPausa);

    if (_asistenciaId != null) {
      await prefs.setInt(_k('fichaje_asistencia_id'), _asistenciaId!);
    } else {
      await prefs.remove(_k('fichaje_asistencia_id'));
    }

    if (_horaEntrada != null) {
      await prefs.setString(
        _k('fichaje_hora_entrada'),
        _horaEntrada!.toIso8601String(),
      );
    } else {
      await prefs.remove(_k('fichaje_hora_entrada'));
    }

    await prefs.setInt(
      _k('fichaje_duracion_acumulada'),
      _duracionAcumulada.inMilliseconds,
    );

    if (_horaInicioPausa != null) {
      await prefs.setString(
        _k('fichaje_hora_inicio_pausa'),
        _horaInicioPausa!.toIso8601String(),
      );
    } else {
      await prefs.remove(_k('fichaje_hora_inicio_pausa'));
    }

    await prefs.setInt(_k('fichaje_total_pausas'), _totalPausas.inMilliseconds);

    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_k('fichaje_fecha_activa'), hoy);
  }

  Future<void> _limpiarEstadoLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_k('fichaje_en_jornada'));
    await prefs.remove(_k('fichaje_en_pausa'));
    await prefs.remove(_k('fichaje_asistencia_id'));
    await prefs.remove(_k('fichaje_hora_entrada'));
    await prefs.remove(_k('fichaje_duracion_acumulada'));
    await prefs.remove(_k('fichaje_hora_inicio_pausa'));
    await prefs.remove(_k('fichaje_total_pausas'));
    await prefs.remove(_k('fichaje_fecha_activa'));

    setState(() {
      _enJornada = false;
      _enPausa = false;
      _asistenciaId = null;
      _horaEntrada = null;
      _duracionAcumulada = Duration.zero;
      _horaInicioPausa = null;
      _totalPausas = Duration.zero;
      _tiempoDisplay = "00:00:00";
      _tiempoPausaDisplay = "00:00:00";
    });

    _detenerTimer();
    _notificarCambios();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _actualizarDisplays();
    });
    _actualizarDisplays();
  }

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _actualizarDisplays() {
    final ahora = DateTime.now();

    if (_enJornada && !_enPausa && _horaEntrada != null) {
      final tiempoActual = ahora.difference(_horaEntrada!);
      final totalEfectivo = _duracionAcumulada + tiempoActual;
      setState(() {
        _tiempoDisplay = _formatearDuracion(totalEfectivo);
      });
    }

    if (_enPausa && _horaInicioPausa != null) {
      final tiempoPausaActual = ahora.difference(_horaInicioPausa!);
      final totalPausa = _totalPausas + tiempoPausaActual;
      setState(() {
        _tiempoPausaDisplay = _formatearDuracion(totalPausa);
      });
    }

    _notificarCambios();
  }

  void _notificarCambios() {
    Duration efectivo = _duracionAcumulada;
    Duration pausa = _totalPausas;

    final ahora = DateTime.now();
    if (_enJornada && !_enPausa && _horaEntrada != null) {
      efectivo += ahora.difference(_horaEntrada!);
    }
    if (_enPausa && _horaInicioPausa != null) {
      pausa += ahora.difference(_horaInicioPausa!);
    }

    widget.onTiempoActualizado(efectivo, pausa);
  }

  String _formatearDuracion(Duration d) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    final horas = dosDigitos(d.inHours);
    final minutos = dosDigitos(d.inMinutes.remainder(60));
    final segundos = dosDigitos(d.inSeconds.remainder(60));
    return "$horas:$minutos:$segundos";
  }

  void _gestionarJornada() async {
    if (_procesando) return;

    if (!_enJornada && _obraSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una obra antes de fichar.'),
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    final ahora = DateTime.now();

    if (!_enJornada) {
      int? nuevoAsistenciaId = await ApiService().ficharEntrada(
        _obraSeleccionadaId!,
      );

      if (!mounted) return;

      if (nuevoAsistenciaId != null) {
        setState(() {
          _asistenciaId = nuevoAsistenciaId;
          _enJornada = true;
          _enPausa = false;
          _horaEntrada = ahora;
          _iniciarTimer();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al conectar con el servidor. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } else {
      bool exito = true;
      if (_asistenciaId != null) {
        exito = await ApiService().ficharSalida(_asistenciaId!);
      }

      if (!mounted) return;

      if (exito) {
        setState(() {
          _enJornada = false;
          _detenerTimer();

          if (!_enPausa && _horaEntrada != null) {
            _duracionAcumulada += ahora.difference(_horaEntrada!);
          } else if (_enPausa && _horaInicioPausa != null) {
            _totalPausas += ahora.difference(_horaInicioPausa!);
          }

          _horaEntrada = null;
          _horaInicioPausa = null;
          _enPausa = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al fichar salida en el servidor.'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _procesando = false);
    }

    await _guardarEstadoLocal();

    if (mounted) {
      _actualizarDisplays();
    }
  }

  void _gestionarPausa() async {
    if (!_enJornada || _procesando) return;

    final ahora = DateTime.now();

    setState(() {
      if (!_enPausa) {
        // INICIAR PAUSA LOCAL
        _enPausa = true;
        _horaInicioPausa = ahora;
        if (_horaEntrada != null) {
          _duracionAcumulada += ahora.difference(_horaEntrada!);
          _horaEntrada = null;
        }
      } else {
        // VOLVER AL TRABAJO LOCAL
        _enPausa = false;
        if (_horaInicioPausa != null) {
          _totalPausas += ahora.difference(_horaInicioPausa!);
          _horaInicioPausa = null;
        }
        _horaEntrada = ahora;
      }
    });

    await _guardarEstadoLocal();
    _actualizarDisplays();
  }

  @override
  void dispose() {
    _detenerTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = AppColors.primaryDark;
    if (_enJornada && !_enPausa) cardColor = Colors.blue.shade800;
    if (_enPausa) cardColor = const Color.fromARGB(255, 14, 161, 48);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (!_enJornada) _buildSelectorObra(),
            const SizedBox(height: 16),
            _buildTimers(),
            const SizedBox(height: 24),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String statusText = "Fuera de servicio";
    if (_enJornada && !_enPausa) statusText = "Trabajando";
    if (_enPausa) statusText = "Pausa / Comida";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        if (_procesando)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        else
          const Icon(Icons.access_time, color: Colors.white70),
      ],
    );
  }

  Widget _buildSelectorObra() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: AppColors.primaryDark,
          value: _obraSeleccionadaId,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          hint: const Text(
            '¿En qué obra estás hoy?',
            style: TextStyle(color: Colors.white70),
          ),
          items: _misObras.map((obra) {
            return DropdownMenuItem<int>(
              value: obra.id,
              child: Text(
                obra.nombre,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _obraSeleccionadaId = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTimers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tiempo Efectivo",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              _tiempoDisplay,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (_enJornada)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Pausa",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _tiempoPausaDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _procesando ? null : _gestionarJornada,
            style: ElevatedButton.styleFrom(
              backgroundColor: _enJornada
                  ? Colors.red.shade600
                  : Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Icon(_enJornada ? Icons.logout : Icons.login),
            label: Text(
              _enJornada ? "FINALIZAR JORNADA" : "INICIAR JORNADA",
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        if (_enJornada) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _procesando ? null : _gestionarPausa,
              style: ElevatedButton.styleFrom(
                backgroundColor: _enPausa ? Colors.white : Colors.white24,
                foregroundColor: _enPausa
                    ? Colors.orange.shade800
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: Icon(_enPausa ? Icons.play_arrow : Icons.restaurant),
              label: Text(_enPausa ? "VOLVER" : "PAUSA"),
            ),
          ),
        ],
      ],
    );
  }
}
