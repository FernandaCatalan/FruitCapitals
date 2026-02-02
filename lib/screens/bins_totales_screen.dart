import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BinsTotalesScreen extends StatefulWidget {
  const BinsTotalesScreen({super.key});

  @override
  State<BinsTotalesScreen> createState() => _BinsTotalesScreenState();
}

class _BinsTotalesScreenState extends State<BinsTotalesScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('Totales diarios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selected,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) {
                        setState(() => _selected = d);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selected)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('contratistas_bins_daily')
                  .where('dateKey', isEqualTo: dateKey)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final aBins = (a.data()['bins'] ?? 0) as int;
                  final bBins = (b.data()['bins'] ?? 0) as int;
                  return bBins.compareTo(aBins);
                });

                if (docs.isEmpty) {
                  return const Center(child: Text('Sin registros'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final nombre = data['nombre'] ?? '';
                    final rut = data['rut'] ?? '';
                    final bins = data['bins'] ?? 0;

                    return Card(
                      child: ListTile(
                        title: Text(nombre.toString()),
                        subtitle: Text(rut.toString()),
                        trailing: Text(
                          bins.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
