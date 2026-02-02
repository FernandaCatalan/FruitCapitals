import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/pago_config_service.dart';
import '../services/peso_service.dart';
import '../services/tts_service.dart';

class RegistroPesosScreen extends StatefulWidget {
  const RegistroPesosScreen({super.key});

  @override
  State<RegistroPesosScreen> createState() => _RegistroPesosScreenState();
}

class _RegistroPesosScreenState extends State<RegistroPesosScreen> {
  final _rutCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();

  final _pesos = <double>[];
  final _service = PesoService();
  final _config = PagoConfigService();

  bool _saving = false;
  String? _rutInFlight;
  int _binsActual = 0;

  @override
  void initState() {
    super.initState();
    _rutCtrl.addListener(_onRutChanged);
  }

  @override
  void dispose() {
    _rutCtrl.dispose();
    _nombreCtrl.dispose();
    _pesoCtrl.dispose();
    _rutCtrl.removeListener(_onRutChanged);
    super.dispose();
  }

  void _onRutChanged() {
    final rut = _rutCtrl.text.trim();
    if (rut.isEmpty) return;
    _cargarContratista(rut);
  }

  Future<void> _cargarContratista(String rut) async {
    _rutInFlight = rut;
    final doc = await FirebaseFirestore.instance
        .collection('contratistas')
        .doc(rut)
        .get();

    if (!mounted || _rutInFlight != rut) return;
    final data = doc.data();
    if (data == null) return;
    final nombre = data['nombre']?.toString() ?? '';
    if (_nombreCtrl.text != nombre) {
      _nombreCtrl.text = nombre;
    }
  }

  void _addPeso() {
    final v = double.tryParse(_pesoCtrl.text);
    if (v == null || v <= 0) return;
    setState(() {
      _pesos.add(v);
      _pesoCtrl.clear();
    });
  }

  Future<void> _guardar(Map<String, dynamic> cfg) async {
    final rut = _rutCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final bins = _binsActual;

    if (rut.isEmpty || nombre.isEmpty || bins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa datos del contratista y bins')),
      );
      return;
    }

    if (_pesos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa al menos un peso')),
      );
      return;
    }

    final pesoIdeal = (cfg['pesoIdeal'] as num?)?.toDouble() ?? 8.9;
    final pesoMin = (cfg['pesoMin'] as num?)?.toDouble();
    final pesoMax = (cfg['pesoMax'] as num?)?.toDouble();

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _service.registrarPesaje(
        rut: rut,
        nombre: nombre,
        bins: bins,
        pesos: List<double>.from(_pesos),
        uid: uid,
        pesoIdeal: pesoIdeal,
        pesoMin: pesoMin,
        pesoMax: pesoMax,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesaje registrado')),
      );
      await TtsService.instance.speak('Pesaje registrado');

      setState(() {
        _rutCtrl.clear();
        _nombreCtrl.clear();
        _pesos.clear();
        _binsActual = 0;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesaje de cajas')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _config.watchConfig(),
        builder: (context, snapshot) {
          final cfg = snapshot.data ?? {};
          final pesoIdeal = (cfg['pesoIdeal'] as num?)?.toDouble() ?? 8.9;

          return ListView(
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
                      _BinsDelDia(
                        rut: _rutCtrl.text.trim(),
                        onBinsChanged: (v) => _binsActual = v,
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
                        'Pesos (kg)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pesoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Peso de caja',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addPeso(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _addPeso,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(88, 48),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Agregar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_pesos.isEmpty)
                        const Text('Sin pesos agregados')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < _pesos.length; i++)
                              Chip(
                                label: Text(_pesos[i].toStringAsFixed(2)),
                                onDeleted: () {
                                  setState(() => _pesos.removeAt(i));
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _guardar(cfg),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar'),
                ),
              ),
              const SizedBox(height: 16),
              _PesosHistorial(dateKey: DateFormat('yyyy-MM-dd').format(DateTime.now())),
            ],
          );
        },
      ),
    );
  }
}

class _PesosHistorial extends StatelessWidget {
  final String dateKey;

  const _PesosHistorial({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bins_pesos_samples')
          .where('dateKey', isEqualTo: dateKey)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTs = a.data()['fecha'] as Timestamp?;
          final bTs = b.data()['fecha'] as Timestamp?;
          final aMs = aTs?.millisecondsSinceEpoch ?? 0;
          final bMs = bTs?.millisecondsSinceEpoch ?? 0;
          return bMs.compareTo(aMs);
        });
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin registros hoy'),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial hoy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...docs.map((d) {
                  final data = d.data();
                  final nombre = data['nombre'] ?? '';
                  final rut = data['rut'] ?? '';
                  final avg = (data['promedio'] ?? 0).toString();
                  final anomalo = data['anomalo'] == true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(nombre.toString()),
                    subtitle: Text(rut.toString()),
                    trailing: SizedBox(
                      width: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Prom: $avg'),
                          Text(
                            anomalo ? 'Anomalo' : 'OK',
                            style: TextStyle(
                              color: anomalo ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BinsDelDia extends StatelessWidget {
  final String rut;
  final ValueChanged<int> onBinsChanged;

  const _BinsDelDia({
    required this.rut,
    required this.onBinsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (rut.isEmpty) {
      return const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Bins del dia',
          border: OutlineInputBorder(),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bins_recepciones')
          .where('dateKey', isEqualTo: dateKey)
          .where('rut', isEqualTo: rut)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int toInt(dynamic v) {
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? 0;
        }
        int bins = 0;
        for (final d in docs) {
          bins += toInt(d.data()['bins']);
        }
        onBinsChanged(bins);

        return TextField(
          readOnly: true,
          controller: TextEditingController(text: bins.toString()),
          decoration: const InputDecoration(
            labelText: 'Bins del dia',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }
}
