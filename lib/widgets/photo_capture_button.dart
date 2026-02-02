import 'package:flutter/material.dart';
import '../models/geo_photo.dart';
import '../services/photo_service.dart';

class PhotoCaptureButton extends StatefulWidget {
  final Function(GeoPhoto) onPhotoCaptured;
  final String label;

  const PhotoCaptureButton({
    super.key,
    required this.onPhotoCaptured,
    this.label = 'Tomar foto',
  });

  @override
  State<PhotoCaptureButton> createState() => _PhotoCaptureButtonState();
}

class _PhotoCaptureButtonState extends State<PhotoCaptureButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt),
      label: Text(widget.label),
      onPressed: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);

              try {
                final photo = await PhotoService.captureGeoPhoto();
                if (photo != null) {
                  widget.onPhotoCaptured(photo);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
    );
  }
}
