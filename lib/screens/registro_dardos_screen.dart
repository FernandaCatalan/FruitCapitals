import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/floracion_service.dart';
import '../services/location_service.dart';
import '../services/tts_service.dart';

class RegistroDardosScreen extends StatefulWidget {
  final String cuartelId;
  final String cuartelNombre;
  final String hileraId;
  final int numeroHilera;
  final String mataId;
  final int numeroMata;

  const RegistroDardosScreen({
    super.key,
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hileraId,
    required this.numeroHilera,
    required this.mataId,
    required this.numeroMata,
  });

  @override
  State<RegistroDardosScreen> createState() => _RegistroDardosScreenState();
}

class _RegistroDardosScreenState extends State<RegistroDardosScreen> {
  late final Map<int, int> _conteoPorYema;
  int _ramillas = 0;
  final FloracionService _service = FloracionService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _conteoPorYema = {for (int yemas = 3; yemas <= 10; yemas++) yemas: 0};
  }

  Future<void> _guardar() async {
    final conteoPorYema = <int, int>{};
    int totalDardos = 0;

    for (int yemas = 3; yemas <= 10; yemas++) {
      final val = _conteoPorYema[yemas] ?? 0;
      if (val > 0) {
        conteoPorYema[yemas] = val;
        totalDardos += val;
      }
    }

    if (totalDardos == 0 && _ramillas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa al menos un dardo o una ramilla'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _service.registrarConteoDardos(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
        cantidadDardos: totalDardos,
        dardosPorYema: conteoPorYema,
        ramillas: _ramillas,
        uid: uid,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dardos registrados'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      TtsService.instance.speak('Dardos registrados');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteo de dardos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuartel ${widget.cuartelNombre} - Hilera ${widget.numeroHilera} - Planta ${widget.numeroMata}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cantidad de dardos por tipo de yemas (3 a 10)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Total dardos: ${_conteoPorYema.values.fold<int>(0, (a, b) => a + b)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Ramillas'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _saving || _ramillas == 0
                          ? null
                          : () => setState(() => _ramillas = _ramillas - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_ramillas',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _ramillas = _ramillas + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (_, index) {
                  final yemas = index + 3;
                  final cantidad = _conteoPorYema[yemas] ?? 0;
                  return ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _conteoPorYema[yemas] = cantidad + 1;
                            });
                          },
                    onLongPress: _saving
                        ? null
                        : () {
                            if (cantidad == 0) return;
                            setState(() {
                              _conteoPorYema[yemas] = cantidad - 1;
                            });
                          },
                    child: Text(
                      '$yemas yemas\n$cantidad',
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
                onPressed: _saving ? null : _guardar,
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
