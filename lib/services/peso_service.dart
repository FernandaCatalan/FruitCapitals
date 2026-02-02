import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PesoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registrarPesaje({
    required String rut,
    required String nombre,
    required int bins,
    required List<double> pesos,
    required String uid,
    required double pesoIdeal,
    double? pesoMin,
    double? pesoMax,
  }) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final avg = _mean(pesos);
    final std = _stdDev(pesos, avg);

    final min = pesoMin ?? (pesoIdeal * 0.85);
    final max = pesoMax ?? (pesoIdeal * 1.15);

    final isAnomalo = avg < min || avg > max;

    final data = {
      'rut': rut,
      'nombre': nombre,
      'bins': bins,
      'cajasPorBin': 24,
      'totalCajas': bins * 24,
      'pesos': pesos,
      'promedio': avg,
      'std': std,
      'pesoIdeal': pesoIdeal,
      'pesoMin': min,
      'pesoMax': max,
      'anomalo': isAnomalo,
      'dateKey': dateKey,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    };

    final sampleRef = _db.collection('bins_pesos_samples').doc();
    final dailyRef = _db.collection('contratistas_pesos_daily').doc('${dateKey}_$rut');

    final batch = _db.batch();
    batch.set(sampleRef, data);

    batch.set(dailyRef, {
      'rut': rut,
      'nombre': nombre,
      'dateKey': dateKey,
      'totalPeso': FieldValue.increment(avg * pesos.length),
      'totalMuestras': FieldValue.increment(pesos.length),
      'totalCajas': FieldValue.increment(bins * 24),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  double _stdDev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    double sum = 0;
    for (final v in values) {
      sum += (v - mean) * (v - mean);
    }
    return math.sqrt(sum / (values.length - 1));
  }
}
