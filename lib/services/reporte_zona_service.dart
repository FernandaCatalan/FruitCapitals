import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ReporteZonaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<File> generarReportePorZona() async {
    final snapshot = await _firestore.collection('entregas').get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No hay entregas registradas');
    }

    final Map<String, double> totalPorCuartel = {};
    final Map<String, int> conteoPorCuartel = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final String cuartel =
          data['cuartelNombre'] ?? 'Sin cuartel';

      double kilos = 0;
      final valorKilos = data['kilos'] ?? data['cantidad'];

      if (valorKilos is int) {
        kilos = valorKilos.toDouble();
      } else if (valorKilos is double) {
        kilos = valorKilos;
      } else if (valorKilos is String) {
        kilos = double.tryParse(valorKilos) ?? 0;
      }

      totalPorCuartel[cuartel] =
          (totalPorCuartel[cuartel] ?? 0) + kilos;
      conteoPorCuartel[cuartel] =
          (conteoPorCuartel[cuartel] ?? 0) + 1;
    }

    final excel = Excel.createExcel();
    const sheetName = 'Reporte por zona';
    excel.rename('Sheet1', sheetName);
    final Sheet sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue('Cuartel'),
      TextCellValue('Total Kilos'),
      TextCellValue('Entregas'),
    ]);

    totalPorCuartel.forEach((cuartel, totalKg) {
      sheet.appendRow([
        TextCellValue(cuartel),
        DoubleCellValue(totalKg),
        IntCellValue(conteoPorCuartel[cuartel] ?? 0),
      ]);
    });

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reporte_por_zona.xlsx');

    await file.writeAsBytes(bytes, flush: true);

    return file;
  }
}
