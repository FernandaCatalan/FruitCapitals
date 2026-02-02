import 'package:cloud_firestore/cloud_firestore.dart';

class FrutoFlor {
  final String id;
  final int florNumero;
  final int cantidadFrutos;
  final DateTime fecha;
  final String uid;

  FrutoFlor({
    required this.id,
    required this.florNumero,
    required this.cantidadFrutos,
    required this.fecha,
    required this.uid,
  });

  factory FrutoFlor.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return FrutoFlor(
      id: id,
      florNumero: (data['florNumero'] ?? 0) as int,
      cantidadFrutos: (data['cantidadFrutos'] ?? 0) as int,
      fecha: parseDate(data['fecha']),
      uid: (data['uid'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'florNumero': florNumero,
      'cantidadFrutos': cantidadFrutos,
      'fecha': Timestamp.fromDate(fecha),
      'uid': uid,
    };
  }
}
