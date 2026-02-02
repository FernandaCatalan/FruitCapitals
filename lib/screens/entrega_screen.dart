import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/cuartel.dart';
import '../services/firestore_service.dart';
import '../services/tts_service.dart';

class EntregaScreen extends StatefulWidget {
  const EntregaScreen({super.key});

  @override
  State<EntregaScreen> createState() => _EntregaScreenState();
}

class _EntregaScreenState extends State<EntregaScreen> {
  final TextEditingController _cantidadCtrl = TextEditingController();

  final FirestoreService _firestore = FirestoreService();

  Cuartel? _cuartelSeleccionado;
  List<Cuartel> _cuarteles = [];

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCuarteles();
  }

  Future<void> _loadCuarteles() async {
    final cuarteles = await _firestore.getCuarteles().first;

    if (!mounted) return;

    setState(() {
      _cuarteles = cuarteles;
      _loading = false;
    });
  }

  Future<void> _saveEntrega() async {
    if (_cuartelSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar un cuartel'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    final cantidad = double.tryParse(_cantidadCtrl.text);

    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cantidad inválida'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final refPoint = _cuartelSeleccionado!.puntos.first;

    await _firestore.saveEntrega({
      'id': const Uuid().v4(),
      'cuartelId': _cuartelSeleccionado!.id,
      'cuartelNombre': _cuartelSeleccionado!.nombre,
      'cantidad': cantidad,
      'latitude': refPoint.latitude,
      'longitude': refPoint.longitude,
      'fecha': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Entrega registrada'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    await TtsService.instance.speak('Entrega registrada');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar entrega')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuartel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),

                  DropdownButtonFormField<Cuartel>(
                    value: _cuartelSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecciona un cuartel',
                    ),
                    items: _cuarteles.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _cuartelSeleccionado = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Cantidad (kg)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),

                  TextField(
                    controller: _cantidadCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 150',
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveEntrega,
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar entrega'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
