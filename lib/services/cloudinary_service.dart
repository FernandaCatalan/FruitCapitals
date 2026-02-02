import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'daepk8a4t';
  static const String uploadPreset = 'Observations';

  Future<String> uploadImage(File image) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Error al subir imagen a Cloudinary');
    }

    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    return data['secure_url']; 
  }
}
