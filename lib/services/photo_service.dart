import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/geo_photo.dart';

class PhotoService {
  static final _picker = ImagePicker();

  static Future<GeoPhoto?> captureGeoPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return GeoPhoto(
      path: image.path,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }
}
