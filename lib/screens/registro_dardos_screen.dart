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
  final _cantidadCtrl = TextEditingController();
  final FloracionService _service = FloracionService();
  bool _saving = false;

  Future<void> _guardar() async {
    final cantidad = int.tryParse(_cantidadCtrl.text);

    if (cantidad == null || cantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa un valor valido'),
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
        cantidadDardos: cantidad,
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
      await TtsService.instance.speak('Dardos registrados');

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
    _cantidadCtrl.dispose();
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
              'Cantidad de dardos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ej: 5',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
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
