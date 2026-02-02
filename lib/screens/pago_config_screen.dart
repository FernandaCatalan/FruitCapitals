import 'package:flutter/material.dart';

import '../services/pago_config_service.dart';

class PagoConfigScreen extends StatefulWidget {
  const PagoConfigScreen({super.key});

  @override
  State<PagoConfigScreen> createState() => _PagoConfigScreenState();
}

class _PagoConfigScreenState extends State<PagoConfigScreen> {
  final _pesoIdealCtrl = TextEditingController();
  final _pagoBaseCtrl = TextEditingController();
  final _pesoMinCtrl = TextEditingController();
  final _pesoMaxCtrl = TextEditingController();

  final _service = PagoConfigService();
  bool _saving = false;

  @override
  void dispose() {
    _pesoIdealCtrl.dispose();
    _pagoBaseCtrl.dispose();
    _pesoMinCtrl.dispose();
    _pesoMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final pesoIdeal = double.tryParse(_pesoIdealCtrl.text);
    final pagoBase = int.tryParse(_pagoBaseCtrl.text);
    final pesoMin = double.tryParse(_pesoMinCtrl.text);
    final pesoMax = double.tryParse(_pesoMaxCtrl.text);

    if (pesoIdeal == null || pagoBase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa peso ideal y pago base')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.saveConfig(
        pesoIdeal: pesoIdeal,
        pagoBasePorCaja: pagoBase,
        pesoMin: pesoMin,
        pesoMax: pesoMax,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuracion guardada')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago por caja')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _service.watchConfig(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          if (_pesoIdealCtrl.text.isEmpty && data['pesoIdeal'] != null) {
            _pesoIdealCtrl.text = data['pesoIdeal'].toString();
          }
          if (_pagoBaseCtrl.text.isEmpty && data['pagoBasePorCaja'] != null) {
            _pagoBaseCtrl.text = data['pagoBasePorCaja'].toString();
          }
          if (_pesoMinCtrl.text.isEmpty && data['pesoMin'] != null) {
            _pesoMinCtrl.text = data['pesoMin'].toString();
          }
          if (_pesoMaxCtrl.text.isEmpty && data['pesoMax'] != null) {
            _pesoMaxCtrl.text = data['pesoMax'].toString();
          }

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
                        'Configuracion',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pesoIdealCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso ideal (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pagoBaseCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pago base por caja',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pesoMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso minimo (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pesoMaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso maximo (opcional)',
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
            ],
          );
        },
      ),
    );
  }
}
