import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/floracion_service.dart';
import '../services/location_service.dart';
import '../services/tts_service.dart';

class RegistroFrutosFlorScreen extends StatefulWidget {
  final String mataId;
  final String cuartelId;
  final String hileraId;
  final String? dardoIdPreseleccionado;

  const RegistroFrutosFlorScreen({
    super.key,
    required this.mataId,
    this.dardoIdPreseleccionado,
    required this.cuartelId,
    required this.hileraId,
  });

  @override
  State<RegistroFrutosFlorScreen> createState() => _RegistroFrutosFlorScreenState();
}

class _RegistroFrutosFlorScreenState extends State<RegistroFrutosFlorScreen> {
  final FloracionService _service = FloracionService();
  late final Map<int, int> _frutosPorYemaUi;
  Map<int, int> _dardosPorYema = {};
  final Map<int, TextEditingController> _frutosControllers = {};
  bool _modoManual = false;

  bool _loadingDardos = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _frutosPorYemaUi = {for (int yemas = 3; yemas <= 10; yemas++) yemas: 0};
    _cargarDardosPorYema();
  }

  Future<void> _cargarDardosPorYema() async {
    try {
      final data = await _service.getUltimoConteoDardosPorYema(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
      );
      if (!mounted) return;
      setState(() => _dardosPorYema = data);
      if (_modoManual) {
        _syncFrutosControllers();
      }
    } finally {
      if (mounted) {
        setState(() => _loadingDardos = false);
      }
    }
  }

  void _syncFrutosControllers() {
    for (final entry in _dardosPorYema.entries) {
      final yemas = entry.key;
      final value = _frutosPorYemaUi[yemas] ?? 0;
      final controller = _frutosControllers.putIfAbsent(
        yemas,
        () => TextEditingController(text: '$value'),
      );
      if (controller.text != '$value') {
        controller.text = '$value';
      }
    }
  }

  void _onFrutosChanged(int yemas, String value) {
    final parsed = int.tryParse(value) ?? 0;
    setState(() {
      _frutosPorYemaUi[yemas] = parsed;
    });
  }

  Future<void> _guardar() async {
    if (_dardosPorYema.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero registra el conteo de dardos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final frutosPorYema = <int, int>{};
    int total = 0;
    for (final entry in _dardosPorYema.entries) {
      final yemas = entry.key;
      final value = _frutosPorYemaUi[yemas] ?? 0;
      if (value < 0) continue;
      frutosPorYema[yemas] = value;
      total += value;
    }

    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un fruto por tipo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _service.registrarConteoFrutosPorYema(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
        frutosPorYema: frutosPorYema,
        uid: uid,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Frutos registrados'),
          backgroundColor: Colors.green,
        ),
      );
      TtsService.instance.speak('Frutos registrados');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _frutosControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiposYema = _dardosPorYema.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Conteo de frutos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa frutos por tipo de dardo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Total frutos por dardo: ${_dardosPorYema.keys.fold<int>(0, (sum, y) => sum + (_frutosPorYemaUi[y] ?? 0))}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ingreso manual'),
              subtitle:
                  const Text('Escribe el numero en vez de usar +/-'),
              value: _modoManual,
              onChanged: _saving || _loadingDardos || _dardosPorYema.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _modoManual = value;
                        if (_modoManual) {
                          _syncFrutosControllers();
                        }
                      });
                    },
            ),
            const SizedBox(height: 6),
            if (_loadingDardos)
              const Center(child: CircularProgressIndicator())
            else if (_dardosPorYema.isEmpty)
              const Text(
                'No hay conteo de dardos por yemas para esta planta. Registra dardos primero.',
                style: TextStyle(color: Colors.orange),
              )
            else
              Expanded(
                child: GridView.builder(
                  itemCount: tiposYema.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.7,
                  ),
                  itemBuilder: (_, index) {
                    final yemas = tiposYema[index];
                    final cantidadDardos = _dardosPorYema[yemas]!;
                    final frutos = _frutosPorYemaUi[yemas] ?? 0;
                    if (_modoManual) {
                      final controller = _frutosControllers.putIfAbsent(
                        yemas,
                        () => TextEditingController(text: '$frutos'),
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$yemas yemas ($cantidadDardos dardos)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: controller,
                                enabled: !_saving,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: '0',
                                ),
                                onChanged: (value) =>
                                    _onFrutosChanged(yemas, value),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                _frutosPorYemaUi[yemas] = frutos + 1;
                              });
                            },
                      onLongPress: _saving
                          ? null
                          : () {
                              if (frutos == 0) return;
                              setState(() {
                                _frutosPorYemaUi[yemas] = frutos - 1;
                              });
                            },
                      child: Text(
                        '$yemas yemas ($cantidadDardos dardos)\n$frutos frutos/dardo',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _loadingDardos || _dardosPorYema.isEmpty
                    ? null
                    : _guardar,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
