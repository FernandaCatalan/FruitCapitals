import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReporteFrutaScreen extends StatefulWidget {
  const ReporteFrutaScreen({super.key});

  @override
  State<ReporteFrutaScreen> createState() => _ReporteFrutaScreenState();
}

class _ReporteFrutaScreenState extends State<ReporteFrutaScreen> {
  DateTime _selected = DateTime.now();
  String _seasonKey = DateTime.now().year.toString();
  late final TextEditingController _seasonCtrl;

  @override
  void initState() {
    super.initState();
    _seasonCtrl = TextEditingController(text: _seasonKey);
  }

  @override
  void dispose() {
    _seasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de fruta')),
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
                    'Filtros',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                            if (d != null) setState(() => _selected = d);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('dd/MM/yyyy').format(_selected)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _seasonCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Temporada (año)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            final trimmed = v.trim();
                            if (trimmed.isNotEmpty) {
                              _seasonKey = trimmed;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ReporteSeccion(
            title: 'Totales diarios',
            stream: FirebaseFirestore.instance
                .collection('contratistas_fruta_daily')
                .where('dateKey', isEqualTo: dateKey)
                .snapshots(),
          ),
          const SizedBox(height: 12),
          _ReporteSeccion(
            title: 'Totales temporada',
            stream: FirebaseFirestore.instance
                .collection('contratistas_fruta_temporada')
                .where('seasonKey', isEqualTo: _seasonKey)
                .snapshots(),
          ),
        ],
      ),
    );
  }
}

class _ReporteSeccion extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _ReporteSeccion({
    required this.title,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int toInt(dynamic v) {
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? 0;
        }
        docs.sort((a, b) {
          final aBins = toInt(a.data()['bins']);
          final bBins = toInt(b.data()['bins']);
          return bBins.compareTo(aBins);
        });

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  const Text('Sin registros')
                else
                  Column(
                    children: [
                      _TopPieChart(docs: docs),
                      const SizedBox(height: 12),
                      ...docs.map((d) {
                        final data = d.data();
                        final nombre = data['nombre'] ?? '';
                        final rut = data['rut'] ?? '';
                        final bins = toInt(data['bins']);
                      final tipo = _mapToChips(data['tipoCounts']);

                        return ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(nombre.toString().isEmpty ? rut.toString() : nombre.toString()),
                          subtitle: Text('RUT: $rut'),
                          trailing: Text(
                            bins.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                          _Breakdown(title: 'Tipo', chips: tipo),
                          const SizedBox(height: 8),
                        ],
                      );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _mapToChips(dynamic raw) {
    if (raw is! Map) return [];
    final entries = raw.entries.toList();
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }
    entries.sort((a, b) => toInt(b.value).compareTo(toInt(a.value)));
    return entries.map((e) {
      return Chip(
        label: Text('${e.key}: ${toInt(e.value)}'),
      );
    }).toList();
  }
}

class _Breakdown extends StatelessWidget {
  final String title;
  final List<Widget> chips;

  const _Breakdown({
    required this.title,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}

class _TopPieChart extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _TopPieChart({required this.docs});

  @override
  Widget build(BuildContext context) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final top = docs.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final total = top.fold<int>(0, (sum, d) => sum + toInt(d.data()['bins']));
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top contratistas (bins)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (int i = 0; i < top.length; i++)
                  PieChartSectionData(
                    color: colors[i % colors.length],
                    value: toInt(top[i].data()['bins']).toDouble(),
                    title: '',
                    radius: 60,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (int i = 0; i < top.length; i++)
              _LegendItem(
                color: colors[i % colors.length],
                label:
                    '${top[i].data()['nombre'] ?? top[i].data()['rut']}: ${toInt(top[i].data()['bins'])}',
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
