import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ReportePagosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<File> generarReportePagos({
    required String dateKey,
    required double pesoIdeal,
    required double pagoBase,
  }) async {
    final recepciones = await _firestore
        .collection('bins_recepciones')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final pesosDaily = await _firestore
        .collection('contratistas_pesos_daily')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final descuentos = await _firestore
        .collection('descuentos_contratista')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final Map<String, _PagoRowData> rows = {};

    for (final d in recepciones.docs) {
      final data = d.data();
      final rut = data['rut']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final bins = (data['bins'] ?? 0) as int;
      rows.putIfAbsent(rut, () => _PagoRowData(rut: rut, nombre: nombre));
      rows[rut]!.bins += bins;
    }

    for (final d in pesosDaily.docs) {
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

    for (final d in descuentos.docs) {
      final data = d.data();
      final rut = data['rut']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final monto = (data['monto'] ?? 0).toDouble();
      rows.putIfAbsent(rut, () => _PagoRowData(rut: rut, nombre: nombre));
      rows[rut]!.descuentos += monto;
      rows[rut]!.nombre = nombre;
    }

    final excel = Excel.createExcel();
    const sheetName = 'Reporte pagos';
    excel.rename('Sheet1', sheetName);
    final Sheet sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Nombre'),
      TextCellValue('RUT'),
      TextCellValue('Bins'),
      TextCellValue('Cajas'),
      TextCellValue('Promedio kg'),
      TextCellValue('Pago por caja'),
      TextCellValue('Bruto'),
      TextCellValue('Descuentos'),
      TextCellValue('Neto'),
    ]);

    for (final row in rows.values) {
      final totalCajas = row.bins * 24;
      final promedio = row.promedio == 0 ? pesoIdeal : row.promedio;
      final pagoPorCaja = pagoBase * (promedio / pesoIdeal);
      final bruto = pagoPorCaja * totalCajas;
      final neto = bruto - row.descuentos;

      sheet.appendRow([
        TextCellValue(dateKey),
        TextCellValue(row.nombre),
        TextCellValue(row.rut),
        IntCellValue(row.bins),
        IntCellValue(totalCajas),
        DoubleCellValue(promedio),
        DoubleCellValue(pagoPorCaja),
        DoubleCellValue(bruto),
        DoubleCellValue(row.descuentos),
        DoubleCellValue(neto),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reporte_pagos_$dateKey.xlsx');

    await file.writeAsBytes(bytes, flush: true);

    return file;
  }
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
