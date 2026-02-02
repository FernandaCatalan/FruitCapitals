import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReporteDescuentosScreen extends StatefulWidget {
  const ReporteDescuentosScreen({super.key});

  @override
  State<ReporteDescuentosScreen> createState() => _ReporteDescuentosScreenState();
}

class _ReporteDescuentosScreenState extends State<ReporteDescuentosScreen> {
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
      appBar: AppBar(title: const Text('Reporte de devoluciones')),
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
                          label:
                              Text(DateFormat('dd/MM/yyyy').format(_selected)),
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
          _ReporteDescuentosSeccion(
            title: 'Diario',
            stream: FirebaseFirestore.instance
                .collection('descuentos_contratista')
                .where('dateKey', isEqualTo: dateKey)
                .snapshots(),
          ),
          const SizedBox(height: 12),
          _ReporteDescuentosSeccion(
            title: 'Temporada',
            stream: FirebaseFirestore.instance
                .collection('descuentos_contratista')
                .where('seasonKey', isEqualTo: _seasonKey)
                .snapshots(),
          ),
        ],
      ),
    );
  }
}

class _ReporteDescuentosSeccion extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _ReporteDescuentosSeccion({
    required this.title,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        double toDouble(dynamic v) {
          if (v is double) return v;
          if (v is int) return v.toDouble();
          if (v is num) return v.toDouble();
          return double.tryParse(v.toString()) ?? 0;
        }

        final Map<String, double> totalPorMotivo = {};
        final Map<String, _ContratistaRow> totalPorContratista = {};
        double totalMonto = 0;

        for (final d in docs) {
          final data = d.data();
          final motivo = data['motivo']?.toString().trim();
          final motivoKey = (motivo == null || motivo.isEmpty)
              ? 'Sin motivo'
              : motivo;
          final rut = data['rut']?.toString() ?? '';
          final nombre = data['nombre']?.toString() ?? '';
          final key = nombre.isEmpty ? rut : nombre;
          final monto = toDouble(data['monto']);

          totalMonto += monto;
          totalPorMotivo[motivoKey] =
              (totalPorMotivo[motivoKey] ?? 0) + monto;

          totalPorContratista.putIfAbsent(
            key,
            () => _ContratistaRow(nombre: nombre, rut: rut),
          );
          totalPorContratista[key]!.monto += monto;
          totalPorContratista[key]!.count += 1;
        }

        final motivosOrdenados = totalPorMotivo.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final contratistasOrdenados = totalPorContratista.values.toList()
          ..sort((a, b) => b.monto.compareTo(a.monto));

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
                else ...[
                  _ResumenTile(
                    label: 'Total descuentos',
                    value: money.format(totalMonto),
                  ),
                  _ResumenTile(
                    label: 'Registros',
                    value: docs.length.toString(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Por motivo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in motivosOrdenados)
                        Chip(
                          label: Text('${e.key}: ${money.format(e.value)}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Por contratista',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...contratistasOrdenados.map((c) {
                    final title = c.nombre.isEmpty ? c.rut : c.nombre;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: Text('RUT: ${c.rut} · ${c.count} registros'),
                      trailing: Text(
                        money.format(c.monto),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResumenTile extends StatelessWidget {
  final String label;
  final String value;

  const _ResumenTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ContratistaRow {
  final String nombre;
  final String rut;
  double monto = 0;
  int count = 0;

  _ContratistaRow({
    required this.nombre,
    required this.rut,
  });
}
