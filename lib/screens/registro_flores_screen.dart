import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/floracion_service.dart';
import '../services/location_service.dart';
import '../services/tts_service.dart';

class RegistroFloresScreen extends StatefulWidget {
  final String mataId;
  final String cuartelId;
  final String hileraId;
  final String? dardoIdPreseleccionado;

  const RegistroFloresScreen({
    super.key,
    required this.mataId,
    this.dardoIdPreseleccionado, 
    required this.cuartelId, 
    required this.hileraId,
  });

  @override
  State<RegistroFloresScreen> createState() => _RegistroFloresScreenState();
}

class _RegistroFloresScreenState extends State<RegistroFloresScreen> {
  final _cantidadCtrl = TextEditingController();
  final FloracionService _service = FloracionService();

  String? _dardoIdSeleccionado;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dardoIdSeleccionado = widget.dardoIdPreseleccionado;
  }

  Future<void> _guardar() async {
    final cantidad = int.tryParse(_cantidadCtrl.text);

    if (_dardoIdSeleccionado == null || cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _service.registrarFlores(
        cuartelId: widget.cuartelId,
        hileraId: widget.hileraId,
        mataId: widget.mataId,
        dardoId: _dardoIdSeleccionado!,
        cantidadFlores: cantidad,
        uid: uid,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🌸 Flores registradas'), backgroundColor: Colors.green),
      );
      await TtsService.instance.speak('Flores registradas');

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
      appBar: AppBar(title: const Text('Conteo de flores')),
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
                final selected = ids.contains(_dardoIdSeleccionado)
                    ? _dardoIdSeleccionado
                    : null;

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
                  onChanged: (v) => setState(() => _dardoIdSeleccionado = v),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text('Cantidad de flores', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ej: 20',
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
