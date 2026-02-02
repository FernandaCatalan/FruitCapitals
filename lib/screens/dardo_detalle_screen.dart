import 'package:flutter/material.dart';
import 'package:FruitCapitals/screens/registros_frutos_flor_screen.dart';

import '../services/floracion_service.dart';
import 'registro_flores_screen.dart';
import 'registros_frutos_flor_screen.dart';

class DardoDetalleScreen extends StatelessWidget {
  final String cuartelId;
  final String cuartelNombre;
  final String hileraId;
  final int numeroHilera;
  final String dardoId;
  final String mataId;
  final int numeroMata;
  final int dardoNumero;

  DardoDetalleScreen({
    super.key,
    required this.dardoId,
    required this.dardoNumero,
    required this.mataId, 
    required this.cuartelId, 
    required this.cuartelNombre, 
    required this.hileraId, 
    required this.numeroHilera, 
    required this.numeroMata,
  });

  final FloracionService _service = FloracionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle – Dardo $dardoNumero'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dardo $dardoNumero', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            StreamBuilder<int?>(
              stream: _service.getTotalFloresActual(
                cuartelId: cuartelId, 
                hileraId: hileraId, 
                mataId: mataId, 
                dardoId: dardoId
                ),
              builder: (context, snapshot) {
                final total = snapshot.data;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_florist),
                    title: const Text('Total de flores registrado'),
                    subtitle: Text(total == null ? 'Aún no hay registro' : '$total flores'),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.local_florist),
                label: const Text('Registrar conteo de flores'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistroFloresScreen(
                        mataId: mataId,
                        cuartelId: cuartelId,
                        hileraId: hileraId,
                        dardoIdPreseleccionado: dardoId,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.apple),
                label: const Text('Registrar frutos por flor'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistroFrutosFlorScreen(
                        mataId: mataId,
                        cuartelId: cuartelId,
                        hileraId: hileraId,
                        dardoIdPreseleccionado: dardoId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
