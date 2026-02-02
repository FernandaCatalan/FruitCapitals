import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _cantidadCtrl = TextEditingController();

  String? _dardoId;
  int? _florNumero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dardoId = widget.dardoIdPreseleccionado;
  }

  Future<void> _guardar() async {
    final frutos = int.tryParse(_cantidadCtrl.text);

    if (_dardoId == null || _florNumero == null || frutos == null || frutos < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _service.registrarFrutosPorFlor(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
        dardoId: _dardoId!,
        florNumero: _florNumero!,
        cantidadFrutos: frutos,
        uid: uid,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🍎 Frutos registrados'), backgroundColor: Colors.green),
      );
      await TtsService.instance.speak('Frutos registrados');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Frutos por flor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dardo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            StreamBuilder(
              stream: _service.getDardosPorMataQuery(
                mataId: widget.mataId,
                cuartelId: widget.cuartelId,
                hileraId: widget.hileraId,
                ),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No hay dardos registrados. Registra primero el conteo de dardos.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  );
                }

                final ids = docs.map((d) => d.id).toSet();
                final selected = ids.contains(_dardoId) ? _dardoId : null;

                return DropdownButtonFormField<String>(
                  value: selected,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona un dardo',
                  ),
                  items: docs.map((d) {
                    return DropdownMenuItem(
                      value: d.id,
                      child: Text('Dardo ${(d.data()['numero'] ?? 0)}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _dardoId = v;
                    _florNumero = null;
                  }),
                );
              },
            ),

            const SizedBox(height: 16),

            if (_dardoId == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Selecciona un dardo para poder elegir una flor.',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              StreamBuilder<int?>(
                stream: _service.getTotalFloresActual(
                  cuartelId: widget.cuartelId,
                  hileraId: widget.hileraId,
                  mataId: widget.mataId,
                  dardoId: _dardoId!,
                ),
                builder: (context, snapshot) {
                  final totalFlores = snapshot.data;

                  if (totalFlores == null || totalFlores == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Primero debes registrar el total de flores para este dardo.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    value: _florNumero,
                    decoration: const InputDecoration(
                      labelText: 'Flor',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(totalFlores, (i) {
                      final n = i + 1;
                      return DropdownMenuItem(
                        value: n,
                        child: Text('Flor $n'),
                      );
                    }),
                    onChanged: (v) => setState(() => _florNumero = v),
                  );
                },
              ),

            const SizedBox(height: 16),
            const Text('Cantidad de frutos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ej: 2',
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
