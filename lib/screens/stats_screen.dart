import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/entrega.dart';
import '../services/firestore_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime? _desde;
  DateTime? _hasta;
  String? _cuartelSeleccionado;

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: StreamBuilder<List<Entrega>>(
        stream: firestore.getEntregas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todas = snapshot.data!;

          if (todas.isEmpty) {
            return const Center(child: Text('No hay entregas'));
          }

          final entregas = todas.where((e) {
            if (_cuartelSeleccionado != null &&
                e.cuartelNombre != _cuartelSeleccionado) {
              return false;
            }

            if (_desde != null && e.fecha.isBefore(_desde!)) {
              return false;
            }

            if (_hasta != null &&
                e.fecha.isAfter(_hasta!.add(const Duration(days: 1)))) {
              return false;
            }

            return true;
          }).toList();

          if (entregas.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay datos para los filtros seleccionados.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          double total = 0;
          final Map<String, double> porCuartel = {};
          final Map<String, double> porDia = {};

          for (final e in entregas) {
            total += e.cantidad;

            porCuartel[e.cuartelNombre] =
                (porCuartel[e.cuartelNombre] ?? 0) + e.cantidad;

            final dia =
                '${e.fecha.year}-${e.fecha.month.toString().padLeft(2, '0')}-${e.fecha.day.toString().padLeft(2, '0')}';

            porDia[dia] = (porDia[dia] ?? 0) + e.cantidad;
          }

          final cuarteles = todas
              .map((e) => e.cuartelNombre)
              .toSet()
              .toList();
          final porCuartelEntries = porCuartel.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final maxCuartelY = porCuartelEntries.isEmpty
              ? 10.0
              : porCuartelEntries
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b) *
                  1.2;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtros',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _cuartelSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Cuartel',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...cuarteles.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _cuartelSeleccionado = v),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDate:
                                      _desde ?? DateTime.now(),
                                );
                                if (d != null) {
                                  setState(() => _desde = d);
                                }
                              },
                              child: Text(
                                _desde == null
                                    ? 'Desde'
                                    : _desde!
                                        .toIso8601String()
                                        .substring(0, 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDate:
                                      _hasta ?? DateTime.now(),
                                );
                                if (d != null) {
                                  setState(() => _hasta = d);
                                }
                              },
                              child: Text(
                                _hasta == null
                                    ? 'Hasta'
                                    : _hasta!
                                        .toIso8601String()
                                        .substring(0, 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Total entregado'),
                      const SizedBox(height: 8),
                      Text(
                        '${total.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entregas por cuartel',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: porCuartelEntries.isEmpty
                            ? const Center(child: Text('Sin datos'))
                            : BarChart(
                                BarChartData(
                                  maxY: maxCuartelY,
                                  barGroups: List.generate(
                                    porCuartelEntries.length,
                                    (index) {
                                      final e = porCuartelEntries[index];
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value,
                                            width: 18,
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, _, rod, __) {
                                        final entry = porCuartelEntries[group.x];
                                        return BarTooltipItem(
                                          '${entry.key}\n${rod.toY.toStringAsFixed(1)} kg',
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 42,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 48,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= porCuartelEntries.length) {
                                            return const SizedBox();
                                          }
                                          final name = porCuartelEntries[idx].key;
                                          final short = name.length > 8
                                              ? '${name.substring(0, 8)}...'
                                              : name;
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            space: 4,
                                            child: Text(
                                              short,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(show: true),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Referencia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(porCuartelEntries.length, (index) {
                        final e = porCuartelEntries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${e.key} - ${e.value.toStringAsFixed(1)} kg'),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Entregas por día',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ...(() {
                final dias = porDia.entries.toList()
                  ..sort((a, b) => b.key.compareTo(a.key));
                final maxDia = dias.isEmpty
                    ? 1.0
                    : dias.map((e) => e.value).reduce((a, b) => a > b ? a : b);
                return dias.map((e) {
                  final progress = maxDia == 0 ? 0.0 : (e.value / maxDia);
                  return ListTile(
                    leading: const Icon(Icons.calendar_today, size: 18),
                    title: Text(e.key),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(value: progress),
                    ),
                    trailing: Text('${e.value.toStringAsFixed(1)} kg'),
                  );
                });
              })(),
            ],
          );
        },
      ),
    );
  }
}

