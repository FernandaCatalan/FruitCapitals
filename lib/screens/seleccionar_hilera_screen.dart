import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeleccionarHileraScreen extends StatelessWidget {
  final String cuartelId;
  final String cuartelNombre;

  const SeleccionarHileraScreen({
    super.key,
    required this.cuartelId,
    required this.cuartelNombre,
  });

  @override
  Widget build(BuildContext context) {
    final hilerasRef = FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .orderBy('numero');

    return Scaffold(
      appBar: AppBar(
        title: Text('Selecciona hilera - $cuartelNombre'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Agregar hilera'),
        onPressed: () => _showCreateHileraDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: hilerasRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No hay hileras registradas',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final int numero = (data['numero'] ?? 0) as int;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.view_stream),
                  title: Text('Hilera $numero'),
                  subtitle: Text('ID: ${doc.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop<Map<String, dynamic>>(context, {
                      'id': doc.id,
                      'numero': numero,
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateHileraDialog(BuildContext context) {
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevas hileras'),
        content: TextField(
          controller: cantidadCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cantidad de hileras',
            hintText: 'Ej: 20',
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

              final hilerasRef = FirebaseFirestore.instance
                  .collection('cuarteles')
                  .doc(cuartelId)
                  .collection('hileras');

              final existingSnap = await hilerasRef.get();
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
                final doc = hilerasRef.doc();
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
                      'Hileras creadas: $created${skipped > 0 ? ' (omitidas $skipped)' : ''}',
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
