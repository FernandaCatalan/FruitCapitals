import 'package:cloud_firestore/cloud_firestore.dart';

class ConteoFlores {
  final String id;
  final int totalFlores;
  final DateTime fecha;
  final String uid;

  ConteoFlores({
    required this.id,
    required this.totalFlores,
    required this.fecha,
    required this.uid,
  });

  factory ConteoFlores.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return ConteoFlores(
      id: id,
      totalFlores: (data['totalFlores'] ?? 0) as int,
      fecha: parseDate(data['fecha']),
      uid: (data['uid'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalFlores': totalFlores,
      'fecha': Timestamp.fromDate(fecha),
      'uid': uid,
    };
  }
}
