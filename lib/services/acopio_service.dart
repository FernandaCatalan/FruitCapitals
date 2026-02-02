import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AcopioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registrarRecepcionBins({
    required String rut,
    required String nombre,
    required int bins,
    required String uid,
    required String tipo,
  }) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final seasonKey = now.year.toString();

    final recepcionRef = _db.collection('bins_recepciones').doc();
    final contratistaRef = _db.collection('contratistas').doc(rut);
    final dailyRef = _db.collection('contratistas_bins_daily').doc('${dateKey}_$rut');
    final frutaDailyRef =
        _db.collection('contratistas_fruta_daily').doc('${dateKey}_$rut');
    final frutaSeasonRef =
        _db.collection('contratistas_fruta_temporada').doc('${seasonKey}_$rut');

    final batch = _db.batch();

    batch.set(recepcionRef, {
      'rut': rut,
      'nombre': nombre,
      'bins': bins,
      'tipo': tipo,
      'dateKey': dateKey,
      'seasonKey': seasonKey,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    });

    batch.set(contratistaRef, {
      'rut': rut,
      'nombre': nombre,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(dailyRef, {
      'rut': rut,
      'nombre': nombre,
      'dateKey': dateKey,
      'bins': FieldValue.increment(bins),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final safeTipo = _safeKey(tipo);

    batch.set(frutaDailyRef, {
      'rut': rut,
      'nombre': nombre,
      'dateKey': dateKey,
      'bins': FieldValue.increment(bins),
      'recepciones': FieldValue.increment(1),
      'tipoCounts.$safeTipo': FieldValue.increment(bins),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(frutaSeasonRef, {
      'rut': rut,
      'nombre': nombre,
      'seasonKey': seasonKey,
      'bins': FieldValue.increment(bins),
      'recepciones': FieldValue.increment(1),
      'tipoCounts.$safeTipo': FieldValue.increment(bins),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  String _safeKey(String value) {
    return value.trim().isEmpty ? 'sin_definir' : value.trim().replaceAll('.', '_');
  }
}
