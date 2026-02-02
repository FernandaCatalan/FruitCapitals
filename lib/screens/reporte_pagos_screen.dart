import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pago_config_service.dart';
import '../services/reporte_pagos_service.dart';

class ReportePagosScreen extends StatefulWidget {
  const ReportePagosScreen({super.key});

  @override
  State<ReportePagosScreen> createState() => _ReportePagosScreenState();
}

class _ReportePagosScreenState extends State<ReportePagosScreen> {
  DateTime _selected = DateTime.now();
  final _config = PagoConfigService();
  final _reporteService = ReportePagosService();
  Future<_ReporteData>? _reportFuture;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _refreshReport();
  }

  void _refreshReport() {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selected);
    _reportFuture = _loadReport(dateKey);
  }

  Future<void> _exportarExcel({
    required String dateKey,
    required double pesoIdeal,
    required double pagoBase,
  }) async {
    setState(() => _exporting = true);

    try {
      final file = await _reporteService.generarReportePagos(
        dateKey: dateKey,
        pesoIdeal: pesoIdeal,
        pagoBase: pagoBase,
      );

      if (!mounted) return;

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: 'Reporte de pagos por contratista',
        subject: 'Reporte de Pagos',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selected);

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de pagos')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _config.watchConfig(),
        builder: (context, configSnap) {
          final cfg = configSnap.data ?? {};
          final pesoIdeal = (cfg['pesoIdeal'] as num?)?.toDouble() ?? 8.9;
          final pagoBase = (cfg['pagoBasePorCaja'] as num?)?.toDouble() ?? 3000;

          return FutureBuilder<_ReporteData>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error al cargar el reporte: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _refreshReport());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('No hay datos para mostrar'));
              }

              final data = snapshot.data!;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                  setState(() {
                                    _selected = d;
                                    _refreshReport();
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(DateFormat('dd/MM/yyyy').format(_selected)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exporting
                                  ? null
                                  : () => _exportarExcel(
                                        dateKey: dateKey,
                                        pesoIdeal: pesoIdeal,
                                        pagoBase: pagoBase,
                                      ),
                              icon: const Icon(Icons.file_download),
                              label: _exporting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Exportar Excel'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text('Sin registros para la fecha seleccionada'),
                      ),
                    ),
                  for (final r in data.rows)
                    _PagoRow(
                      row: r,
                      pesoIdeal: pesoIdeal,
                      pagoBase: pagoBase,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<_ReporteData> _loadReport(String dateKey) async {
    final recepciones = FirebaseFirestore.instance
        .collection('bins_recepciones')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final pesosDaily = FirebaseFirestore.instance
        .collection('contratistas_pesos_daily')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final descuentos = FirebaseFirestore.instance
        .collection('descuentos_contratista')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final results = await Future.wait([
      recepciones,
      pesosDaily,
      descuentos,
    ]).timeout(const Duration(seconds: 20));

    final recepcionesSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final pesosDailySnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final descuentosSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

    final Map<String, _PagoRowData> rows = {};

    for (final d in recepcionesSnap.docs) {
      final data = d.data();
      final rut = data['rut']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final bins = (data['bins'] ?? 0) as int;
      rows.putIfAbsent(rut, () => _PagoRowData(rut: rut, nombre: nombre));
      rows[rut]!.bins += bins;
    }

    for (final d in pesosDailySnap.docs) {
      final data = d.data();
      final rut = data['rut']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final totalPeso = (data['totalPeso'] ?? 0).toDouble();
      final totalMuestras = (data['totalMuestras'] ?? 0).toDouble();
      rows.putIfAbsent(rut, () => _PagoRowData(rut: rut, nombre: nombre));
      if (totalMuestras > 0) {
        rows[rut]!.promedio = totalPeso / totalMuestras;
      }
      rows[rut]!.nombre = nombre;
    }

    for (final d in descuentosSnap.docs) {
      final data = d.data();
      final rut = data['rut']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final monto = (data['monto'] ?? 0).toDouble();
      rows.putIfAbsent(rut, () => _PagoRowData(rut: rut, nombre: nombre));
      rows[rut]!.descuentos += monto;
      rows[rut]!.nombre = nombre;
    }

    return _ReporteData(rows.values.toList());
  }
}

class _PagoRow extends StatelessWidget {
  final _PagoRowData row;
  final double pesoIdeal;
  final double pagoBase;

  const _PagoRow({
    required this.row,
    required this.pesoIdeal,
    required this.pagoBase,
  });

  @override
  Widget build(BuildContext context) {
    final totalCajas = row.bins * 24;
    final promedio = row.promedio == 0 ? pesoIdeal : row.promedio;
    final pagoPorCaja = pagoBase * (promedio / pesoIdeal);
    final bruto = pagoPorCaja * totalCajas;
    final neto = bruto - row.descuentos;

    return Card(
      child: ListTile(
        title: Text(row.nombre.isEmpty ? row.rut : row.nombre),
        subtitle: Text('RUT: ${row.rut} · Bins: ${row.bins} · Cajas: $totalCajas'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Prom: ${promedio.toStringAsFixed(2)} kg'),
            Text('Pago/caja: ${pagoPorCaja.toStringAsFixed(0)}'),
            Text('Neto: ${neto.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class _ReporteData {
  final List<_PagoRowData> rows;

  _ReporteData(this.rows);
}

class _PagoRowData {
  final String rut;
  String nombre;
  int bins = 0;
  double promedio = 0;
  double descuentos = 0;

  _PagoRowData({
    required this.rut,
    required this.nombre,
  });
}
