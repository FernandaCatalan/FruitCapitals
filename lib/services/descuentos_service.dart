import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DescuentosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registrarDescuento({
    required String rut,
    required String nombre,
    required String motivo,
    required double monto,
    required List<String> photoPaths,
    required String uid,
  }) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final seasonKey = now.year.toString();

    await _db.collection('descuentos_contratista').add({
      'rut': rut,
      'nombre': nombre,
      'motivo': motivo,
      'monto': monto,
      'dateKey': dateKey,
      'seasonKey': seasonKey,
      'fotoPaths': photoPaths,
      'fecha': FieldValue.serverTimestamp(),
      'uid': uid,
    });
  }
}
