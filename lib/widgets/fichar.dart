import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart'; // Ajusta esta ruta si es necesario

class FichajeCard extends StatefulWidget {
  final Function(Duration efectivo, Duration pausa) onTiempoActualizado;

  const FichajeCard({super.key, required this.onTiempoActualizado});

  @override
  State<FichajeCard> createState() => _FichajeCardState();
}

class _FichajeCardState extends State<FichajeCard> {
  bool _enJornada = false;
  bool _enPausa = false;

  // Variables para Trabajo
  DateTime? _horaEntrada;
  Duration _duracionAcumulada = Duration.zero;
  String _tiempoDisplay = "00:00:00";

  // Variables para Pausa
  DateTime? _horaInicioPausa;
  Duration _totalPausas = Duration.zero;
  String _tiempoPausaDisplay = "00:00:00";

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarEstadoLocal();
  }

  Future<void> _cargarEstadoLocal() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _enJornada = prefs.getBool('fichaje_jornada') ?? false;
      _enPausa = prefs.getBool('fichaje_pausa') ?? false;

      // Recuperar tiempos de Trabajo
      final horaGuardada = prefs.getString('fichaje_hora_entrada');
      if (horaGuardada != null) {
        _horaEntrada = DateTime.parse(horaGuardada);
      }
      _duracionAcumulada = Duration(seconds: prefs.getInt('fichaje_acumulado') ?? 0);

      // Recuperar tiempos de Pausa
      final horaPausaGuardada = prefs.getString('fichaje_hora_pausa');
      if (horaPausaGuardada != null) {
        _horaInicioPausa = DateTime.parse(horaPausaGuardada);
      }
      _totalPausas = Duration(seconds: prefs.getInt('fichaje_acumulado_pausa') ?? 0);

      if (_enJornada) {
        _iniciarCronometro();
      } else {
        _tiempoDisplay = _formatDuration(_duracionAcumulada);
        _tiempoPausaDisplay = _formatDuration(_totalPausas);
        widget.onTiempoActualizado(_duracionAcumulada, _totalPausas);
      }
    });
  }

  Future<void> _guardarEstadoLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fichaje_jornada', _enJornada);
    await prefs.setBool('fichaje_pausa', _enPausa);
    
    await prefs.setInt('fichaje_acumulado', _duracionAcumulada.inSeconds);
    await prefs.setInt('fichaje_acumulado_pausa', _totalPausas.inSeconds);

    if (_horaEntrada != null) {
      await prefs.setString('fichaje_hora_entrada', _horaEntrada!.toIso8601String());
    } else {
      await prefs.remove('fichaje_hora_entrada');
    }

    if (_horaInicioPausa != null) {
      await prefs.setString('fichaje_hora_pausa', _horaInicioPausa!.toIso8601String());
    } else {
      await prefs.remove('fichaje_hora_pausa');
    }
  }

  void _iniciarJornada() {
    setState(() {
      _enJornada = true;
      _enPausa = false;
      _duracionAcumulada = Duration.zero;
      _totalPausas = Duration.zero;
      _horaEntrada = DateTime.now();
      _horaInicioPausa = null;
      _iniciarCronometro();
    });
    _guardarEstadoLocal();
  }

  void _gestionarPausa() {
    setState(() {
      if (!_enPausa) {
        _enPausa = true;
        if (_horaEntrada != null) {
          _duracionAcumulada += DateTime.now().difference(_horaEntrada!);
          _horaEntrada = null;
        }
        _horaInicioPausa = DateTime.now();
      } else {
        _enPausa = false;
        if (_horaInicioPausa != null) {
          _totalPausas += DateTime.now().difference(_horaInicioPausa!);
          _horaInicioPausa = null;
        }
        _horaEntrada = DateTime.now();
      }
    });
    _guardarEstadoLocal();
  }

  void _finalizarJornada() {
    _timer?.cancel();

    setState(() {
      if (!_enPausa && _horaEntrada != null) {
        _duracionAcumulada += DateTime.now().difference(_horaEntrada!);
      } else if (_enPausa && _horaInicioPausa != null) {
        _totalPausas += DateTime.now().difference(_horaInicioPausa!);
      }

      _enJornada = false;
      _enPausa = false;
      _tiempoDisplay = _formatDuration(_duracionAcumulada);
      _tiempoPausaDisplay = _formatDuration(_totalPausas);
      _horaEntrada = null;
      _horaInicioPausa = null;
    });

    widget.onTiempoActualizado(_duracionAcumulada, _totalPausas);
    _guardarEstadoLocal();
  }

  void _iniciarCronometro() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      Duration tiempoEfectivoActual = _duracionAcumulada;
      Duration tiempoPausaActual = _totalPausas;

      if (_enJornada && !_enPausa && _horaEntrada != null) {
        tiempoEfectivoActual += DateTime.now().difference(_horaEntrada!);
      } else if (_enPausa && _horaInicioPausa != null) {
        tiempoPausaActual += DateTime.now().difference(_horaInicioPausa!);
      }

      setState(() {
        _tiempoDisplay = _formatDuration(tiempoEfectivoActual);
        _tiempoPausaDisplay = _formatDuration(tiempoPausaActual);
      });

      widget.onTiempoActualizado(tiempoEfectivoActual, tiempoPausaActual);
    });
  }

  String _formatDuration(Duration d) {
    return d.toString().split('.').first.padLeft(8, "0");
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = _enPausa
        ? Colors.orange.shade800
        : (_enJornada ? AppColors.primary : Colors.grey.shade800);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contador de Trabajo
              Column(
                children: [
                  const Text("Trabajo", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    _tiempoDisplay,
                    style: TextStyle(
                      color: !_enPausa ? Colors.white : Colors.white54,
                      fontSize: !_enPausa && _enJornada ? 42 : 24, // Grande si está trabajando
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 30),
              // Contador de Pausa
              Column(
                children: [
                  const Text("Pausa", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    _tiempoPausaDisplay,
                    style: TextStyle(
                      color: _enPausa ? Colors.white : Colors.white54,
                      fontSize: _enPausa ? 42 : 24, // Grande si está en pausa
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: !_enJornada ? _iniciarJornada : _finalizarJornada,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _enJornada
                        ? Colors.red.shade500
                        : Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_enJornada ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _enJornada ? "FIN JORNADA" : "ENTRADA",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              if (_enJornada) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _gestionarPausa,
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
          ),
        ],
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
        const Icon(Icons.access_time, color: Colors.white70),
      ],
    );
  }
}