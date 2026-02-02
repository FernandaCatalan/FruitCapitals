import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/geo_photo.dart';
import '../services/cloudinary_service.dart';
import '../services/connectivity_service.dart';
import '../services/descuentos_service.dart';
import '../services/tts_service.dart';
import '../widgets/photo_capture_button.dart';

class RegistroDescuentoScreen extends StatefulWidget {
  const RegistroDescuentoScreen({super.key});

  @override
  State<RegistroDescuentoScreen> createState() => _RegistroDescuentoScreenState();
}

class _RegistroDescuentoScreenState extends State<RegistroDescuentoScreen> {
  final _rutCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  final _photos = <GeoPhoto>[];
  String _motivo = 'muy baja';

  final _service = DescuentosService();
  final _cloudinary = CloudinaryService();
  final _connectivity = ConnectivityService();

  bool _saving = false;

  @override
  void dispose() {
    _rutCtrl.dispose();
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final rut = _rutCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text);

    if (rut.isEmpty || nombre.isEmpty || monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los datos correctamente')),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una foto como evidencia')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final hasInternet = await _connectivity.hasConnection();
      final List<String> photoPaths = [];

      if (hasInternet) {
        for (final p in _photos) {
          final url = await _cloudinary.uploadImage(File(p.path));
          photoPaths.add(url);
        }
      } else {
        photoPaths.addAll(_photos.map((p) => p.path));
      }

      await _service.registrarDescuento(
        rut: rut,
        nombre: nombre,
        motivo: _motivo,
        monto: monto,
        photoPaths: photoPaths,
        uid: uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descuento registrado')),
      );
      await TtsService.instance.speak('Descuento registrado');

      setState(() {
        _rutCtrl.clear();
        _nombreCtrl.clear();
        _montoCtrl.clear();
        _photos.clear();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devolucion / Descuento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contratista', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rutCtrl,
                    decoration: const InputDecoration(
                      labelText: 'RUT',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detalle', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _motivo,
                    items: const [
                      DropdownMenuItem(value: 'muy baja', child: Text('Muy baja')),
                      DropdownMenuItem(value: 'muchas hojas', child: Text('Muchas hojas')),
                      DropdownMenuItem(value: 'sin pedicelo', child: Text('Fruta sin pedicelo')),
                    ],
                    onChanged: (v) => setState(() => _motivo = v ?? 'muy baja'),
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto descuento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PhotoCaptureButton(
                    label: 'Agregar foto',
                    onPhotoCaptured: (p) => setState(() => _photos.add(p)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
    );
  }
}
