import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/floracion_service.dart';
import '../services/tts_service.dart';

class CrearDardoScreen extends StatefulWidget {
  final String cuartelId;
  final String hileraId;
  final String mataId;

  const CrearDardoScreen({
    super.key,
    required this.cuartelId,
    required this.hileraId,
    required this.mataId,
  });

  @override
  State<CrearDardoScreen> createState() => _CrearDardoScreenState();
}

class _CrearDardoScreenState extends State<CrearDardoScreen> {
  final _numeroCtrl = TextEditingController();
  final FloracionService _service = FloracionService();

  bool _saving = false;

  Future<void> _guardarDardo() async {
    final numero = int.tryParse(_numeroCtrl.text);

    if (numero == null || numero <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa un número de dardo válido'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final exists = await _service.existeDardoEnMata(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
        numero: numero,
      );
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ya existe un dardo con ese número en esta planta'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        setState(() => _saving = false);
        return;
      }
      
      await _service.crearDardo(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
        numero: numero,
        uid: uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Dardo creado'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: Duration(seconds: 2),
        ),
      );
      await TtsService.instance.speak('Dardo creado');

      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear dardo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Número de dardo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _numeroCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ej: 1, 2, 3...',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _guardarDardo,
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
