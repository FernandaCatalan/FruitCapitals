import 'package:cloud_firestore/cloud_firestore.dart';

class FlorDardo {
  final String id;
  final String dardoId;
  final int cantidadFlores;
  final String uid;
  final DateTime fecha;

  FlorDardo({
    required this.id,
    required this.dardoId,
    required this.cantidadFlores,
    required this.uid,
    required this.fecha,
  });

  factory FlorDardo.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['fecha'];
    final fecha = (ts is Timestamp) ? ts.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

    return FlorDardo(
      id: id,
      dardoId: (data['dardoId'] ?? '').toString(),
      cantidadFlores: (data['cantidadFlores'] as num).toInt(),
      uid: (data['uid'] ?? '').toString(),
      fecha: fecha,
    );
  }
}
