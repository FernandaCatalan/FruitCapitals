import 'package:cloud_firestore/cloud_firestore.dart';

class Dardo {
  final String id;
  final String mataId;
  final int numero;
  final DateTime fechaRegistro;
  final String uid;

  Dardo({
    required this.id,
    required this.mataId,
    required this.numero,
    required this.fechaRegistro,
    required this.uid,
  });

  factory Dardo.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseFecha(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Dardo(
      id: id,
      mataId: (data['mataId'] ?? '').toString(),
      numero: (data['numero'] as num?)?.toInt() ?? 0,
      fechaRegistro: parseFecha(data['fechaRegistro']),
      uid: (data['uid'] ?? '').toString(),
    );
  }
}
