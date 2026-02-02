import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/acopio_service.dart';
import '../services/tts_service.dart';

class RegistroBinsScreen extends StatefulWidget {
  const RegistroBinsScreen({super.key});

  @override
  State<RegistroBinsScreen> createState() => _RegistroBinsScreenState();
}

class _RegistroBinsScreenState extends State<RegistroBinsScreen> {
  final _rutCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _binsCtrl = TextEditingController();
  String _tipo = 'lapins';

  final _service = AcopioService();
  bool _saving = false;

  @override
  void dispose() {
    _rutCtrl.dispose();
    _nombreCtrl.dispose();
    _binsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final rut = _rutCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final bins = int.tryParse(_binsCtrl.text);
    final tipo = _tipo;

    if (rut.isEmpty || nombre.isEmpty || bins == null || bins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa los datos correctamente'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _service.registrarRecepcionBins(
        rut: rut,
        nombre: nombre,
        bins: bins,
        tipo: tipo,
        uid: uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recepcion registrada'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await TtsService.instance.speak('Recepcion registrada');

      _rutCtrl.clear();
      _nombreCtrl.clear();
      _binsCtrl.clear();
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
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Recepcion de bins')),
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
                    'Contratista',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    items: const [
                      DropdownMenuItem(value: 'lapins', child: Text('Lapins')),
                      DropdownMenuItem(value: 'santina', child: Text('Santina')),
                    ],
                    onChanged: (v) => setState(() => _tipo = v ?? 'lapins'),
                    decoration: const InputDecoration(
                      labelText: 'Tipo de fruta',
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
                  const Text(
                    'Recepcion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _binsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de bins',
                      border: OutlineInputBorder(),
                    ),
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
          const SizedBox(height: 16),
          _ResumenDiario(dateKey: dateKey),
        ],
      ),
    );
  }
}

class _ResumenDiario extends StatelessWidget {
  final String dateKey;

  const _ResumenDiario({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bins_recepciones')
          .where('dateKey', isEqualTo: dateKey)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final Map<String, Map<String, dynamic>> resumen = {};
        int toInt(dynamic v) {
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? 0;
        }
        for (final d in docs) {
          final data = d.data();
          final rut = data['rut']?.toString() ?? '';
          final nombre = data['nombre']?.toString() ?? '';
          final bins = toInt(data['bins']);
          if (!resumen.containsKey(rut)) {
            resumen[rut] = {'rut': rut, 'nombre': nombre, 'bins': 0};
          }
          resumen[rut]!['bins'] = (resumen[rut]!['bins'] as int) + bins;
        }
        final rows = resumen.values.toList();
        rows.sort((a, b) => (b['bins'] as int).compareTo(a['bins'] as int));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conteo diario por contratista',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fecha: $dateKey',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Text('Sin registros hoy')
                else
                  Column(
                    children: rows.map((data) {
                      final nombre = data['nombre'] ?? '';
                      final rut = data['rut'] ?? '';
                      final bins = data['bins'] ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(nombre.toString()),
                        subtitle: Text(rut.toString()),
                        trailing: Text(
                          bins.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
