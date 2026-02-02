import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cuartel.dart';
import '../services/cosecha_service.dart';
import '../services/firestore_service.dart';
import '../services/tts_service.dart';

class RegistroCosechaScreen extends StatefulWidget {
  const RegistroCosechaScreen({super.key});

  @override
  State<RegistroCosechaScreen> createState() => _RegistroCosechaScreenState();
}

class _RegistroCosechaScreenState extends State<RegistroCosechaScreen> {
  final _firestore = FirestoreService();
  final _cosecha = CosechaService();

  final _cosechadasCtrl = TextEditingController();
  final _pendientesCtrl = TextEditingController();

  Cuartel? _cuartel;
  String? _cuartelId;
  String? _hileraId;
  int? _numeroHilera;
  bool _saving = false;

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _hilerasStream() {
    return FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(_cuartelId)
        .collection('hileras')
        .orderBy('numero')
        .snapshots();
  }

  @override
  void dispose() {
    _cosechadasCtrl.dispose();
    _pendientesCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final cosechadas = int.tryParse(_cosechadasCtrl.text);
    final pendientes = int.tryParse(_pendientesCtrl.text);

    if (_cuartelId == null || _hileraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona cuartel y hilera'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    if (cosechadas == null || pendientes == null || cosechadas < 0 || pendientes < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa valores validos'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _cosecha.registrarCosechaHilera(
        cuartelId: _cuartelId!,
        hileraId: _hileraId!,
        cosechadas: cosechadas,
        pendientes: pendientes,
        uid: uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cosecha registrada'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await TtsService.instance.speak('Cosecha registrada');
      setState(() {
        _cosechadasCtrl.clear();
        _pendientesCtrl.clear();
      });
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
  Widget build(BuildContext context) {
    final porcentaje = _calcPorcentaje();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de cosecha')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Cuartel>>(
                    stream: _firestore.getCuarteles(),
                    builder: (context, snapshot) {
                      final cuarteles = snapshot.data ?? [];
                      final ids = cuarteles.map((c) => c.id).toSet();
                      final selectedId = ids.contains(_cuartelId) ? _cuartelId : null;

                      return DropdownButtonFormField<String>(
                        value: selectedId,
                        items: cuarteles
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          final selected =
                              cuarteles.firstWhere((c) => c.id == id);
                          setState(() {
                            _cuartelId = id;
                            _cuartel = selected;
                            _hileraId = null;
                            _numeroHilera = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Cuartel',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_cuartelId != null)
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _hilerasStream(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'No hay hileras registradas',
                              style: TextStyle(color: Colors.orange),
                            ),
                          );
                        }

                        final ids = docs.map((d) => d.id).toSet();
                        final selectedId = ids.contains(_hileraId) ? _hileraId : null;

                        return DropdownButtonFormField<String>(
                          value: selectedId,
                          items: docs
                              .map((d) {
                                final numero = _parseInt(d.data()['numero']);
                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text('Hilera $numero'),
                                );
                              })
                              .toList(),
                          onChanged: (v) {
                            final numero = docs
                                .firstWhere((d) => d.id == v)
                                .data()['numero'];
                            setState(() {
                              _hileraId = v;
                              _numeroHilera = _parseInt(numero);
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Hilera',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
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
                  const Text(
                    'Registro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cosechadasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Plantas cosechadas',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pendientesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Plantas pendientes',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (_numeroHilera != null)
                    Text(
                      'Hilera $_numeroHilera · Avance ${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  double _calcPorcentaje() {
    final c = int.tryParse(_cosechadasCtrl.text) ?? 0;
    final p = int.tryParse(_pendientesCtrl.text) ?? 0;
    final total = c + p;
    if (total == 0) return 0;
    return (c / total) * 100;
  }
}
