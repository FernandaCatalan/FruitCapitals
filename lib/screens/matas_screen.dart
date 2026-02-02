import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:FruitCapitals/screens/dardos_screen.dart';

class MatasScreen extends StatelessWidget {
  final String cuartelId;
  final String hileraId;
  final int numeroHilera;

  final String cuartelNombre;

  const MatasScreen({
    super.key,
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hileraId,
    required this.numeroHilera,
  });


  @override
  Widget build(BuildContext context) {
    final matasRef = FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .doc(hileraId)
        .collection('matas')
        .orderBy('numero');

    return Scaffold(
      appBar: AppBar(
        title: Text('Plantas – Hilera $numeroHilera'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: matasRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No hay plantas registradas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final matas = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: matas.length,
            itemBuilder: (context, index) {
              final data = matas[index].data() as Map<String, dynamic>;
              final numero = data['numero'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DardosScreen(
                        cuartelId: cuartelId,
                        cuartelNombre: cuartelNombre,
                        hileraId: hileraId,
                        numeroHilera: numeroHilera,
                        mataId: matas[index].id,
                        numeroMata: numero,
                      ),
                    ),
                  );
                },

                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Planta $numero',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Agregar planta'),
        onPressed: () => _showCreateMataDialog(context),
      ),
    );
  }

  void _showCreateMataDialog(BuildContext context) {
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevas plantas'),
        content: TextField(
          controller: cantidadCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cantidad de plantas',
            hintText: 'Ej: 80',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = int.tryParse(cantidadCtrl.text);

              if (cantidad == null || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cantidad invalida'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
                return;
              }

              final matasRef = FirebaseFirestore.instance
                  .collection('cuarteles')
                  .doc(cuartelId)
                  .collection('hileras')
                  .doc(hileraId)
                  .collection('matas');

              final existingSnap = await matasRef.get();
              final existing = <int>{};
              for (final d in existingSnap.docs) {
                final data = d.data();
                final numero = data['numero'];
                if (numero is int) {
                  existing.add(numero);
                } else if (numero is num) {
                  existing.add(numero.toInt());
                }
              }

              int created = 0;
              int skipped = 0;
              WriteBatch batch = FirebaseFirestore.instance.batch();
              int batchOps = 0;

              for (int i = 1; i <= cantidad; i++) {
                if (existing.contains(i)) {
                  skipped++;
                  continue;
                }
                final doc = matasRef.doc();
                batch.set(doc, {
                  'numero': i,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                created++;
                batchOps++;
                if (batchOps >= 450) {
                  await batch.commit();
                  batch = FirebaseFirestore.instance.batch();
                  batchOps = 0;
                }
              }

              if (batchOps > 0) {
                await batch.commit();
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Plantas creadas: $created${skipped > 0 ? ' (omitidas $skipped)' : ''}',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

}
