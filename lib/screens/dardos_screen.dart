import 'package:flutter/material.dart';

import '../services/floracion_service.dart';
import 'crear_dardo_screen.dart';
import 'dardo_detalle_screen.dart';

class DardosScreen extends StatelessWidget {
  final String cuartelId;
  final String cuartelNombre;
  final String hileraId;
  final int numeroHilera;
  final String mataId;
  final int numeroMata;

  DardosScreen({
    super.key,
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hileraId,
    required this.numeroHilera,
    required this.mataId,
    required this.numeroMata,
  });

  final FloracionService _service = FloracionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dardos – Planta $numeroMata (Hilera $numeroHilera)'),
      ),
      body: StreamBuilder(
        stream: _service.getDardos(
          cuartelId: cuartelId,
          hileraId: hileraId,
          mataId: mataId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dardos = snapshot.data!;
          if (dardos.isEmpty) {
            return Center(
              child: Text(
                'No hay dardos registrados',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: dardos.length,
            itemBuilder: (_, i) {
              final d = dardos[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.grain),
                  title: Text('Dardo ${d.numero}'),
                  subtitle: Text('ID: ${d.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DardoDetalleScreen(
                          cuartelId: cuartelId,
                          cuartelNombre: cuartelNombre,
                          hileraId: hileraId,
                          numeroHilera: numeroHilera,
                          mataId: mataId,
                          numeroMata: numeroMata,
                          dardoId: d.id,
                          dardoNumero: d.numero,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Crear dardo'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CrearDardoScreen(
                cuartelId: cuartelId,
                hileraId: hileraId,
                mataId: mataId,
              ),
            ),
          );
        },
      ),
    );
  }
}
