import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/geo_photo.dart';
import '../models/observation.dart';
import '../services/cloudinary_service.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/observation_repository.dart';
import '../services/tts_service.dart';
import '../widgets/photo_capture_button.dart';

class ComentarioMataScreen extends StatefulWidget {
  final String cuartelId;
  final String cuartelNombre;
  final String hileraId;
  final int numeroHilera;
  final String mataId;
  final int numeroMata;

  const ComentarioMataScreen({
    super.key,
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hileraId,
    required this.numeroHilera,
    required this.mataId,
    required this.numeroMata,
  });

  @override
  State<ComentarioMataScreen> createState() => _ComentarioMataScreenState();
}

class _ComentarioMataScreenState extends State<ComentarioMataScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final List<GeoPhoto> _photos = [];

  final ObservationRepository _repository = ObservationRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  final CloudinaryService _cloudinary = CloudinaryService();

  bool _saving = false;

  Future<void> _saveObservation() async {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Escribe un comentario'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      final hasInternet = await _connectivity.hasConnection();
      final List<String> finalPhotoPaths = [];

      if (_photos.isNotEmpty) {
        if (hasInternet) {
          for (final photo in _photos) {
            final url = await _cloudinary.uploadImage(File(photo.path));
            finalPhotoPaths.add(url);
          }
        } else {
          finalPhotoPaths.addAll(_photos.map((p) => p.path));
        }
      }

      final obs = Observation(
        id: const Uuid().v4(),
        uid: FirebaseAuth.instance.currentUser!.uid,
        tipo: 'mata_anomala',
        description: comment,
        latitude: pos.latitude,
        longitude: pos.longitude,
        createdAt: DateTime.now(),
        photoPaths: finalPhotoPaths,
        isSynced: hasInternet,
        cuartelId: widget.cuartelId,
        cuartelNombre: widget.cuartelNombre,
        hileraId: widget.hileraId,
        numeroHilera: widget.numeroHilera,
        mataId: widget.mataId,
        numeroMata: widget.numeroMata,
      );

      await _repository.saveObservation(obs);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comentario guardado'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await TtsService.instance.speak('Comentario guardado');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comentario de planta anomala')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cuartel ${widget.cuartelNombre} - Hilera ${widget.numeroHilera} - Planta ${widget.numeroMata}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            PhotoCaptureButton(
              label: 'Agregar foto (opcional)',
              onPhotoCaptured: (photo) {
                setState(() => _photos.add(photo));
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveObservation,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
