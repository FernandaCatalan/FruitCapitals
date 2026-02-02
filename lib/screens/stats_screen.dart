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

              const Text(
                'Entregas por cuartel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 320,
                child: BarChart(
                  BarChartData(
                    barGroups: porCuartel.entries.map((e) {
                      final index = porCuartel.keys.toList().indexOf(e.key);

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            width: 20,
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),

                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),

                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= porCuartel.length) {
                              return const SizedBox();
                            }

                            final cuartel =
                                porCuartel.keys.elementAt(value.toInt());
                            final cantidad = porCuartel[cuartel]!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${cantidad.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= porCuartel.length) {
                              return const SizedBox();
                            }

                            return Transform.rotate(
                              angle: -0.6,
                              child: Text(
                                porCuartel.keys.elementAt(value.toInt()),
                                style: const TextStyle(fontSize: 9),
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

              const SizedBox(height: 24),

              const Text(
                'Entregas por día',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ...porDia.entries.map(
                (e) => ListTile(
                  leading:
                      const Icon(Icons.calendar_today, size: 18),
                  title: Text(e.key),
                  trailing:
                      Text('${e.value.toStringAsFixed(1)} kg'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
