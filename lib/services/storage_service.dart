import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadObservationPhoto({
    required File file,
    required String uid,
  }) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage
        .ref()
        .child('observaciones')
        .child(uid)
        .child('$fileName.jpg');

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    return url;
  }
}
