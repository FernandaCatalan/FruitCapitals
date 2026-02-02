import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/observation.dart';

class EditObservationScreen extends StatefulWidget {
  final Observation observation;

  const EditObservationScreen({super.key, required this.observation});

  @override
  State<EditObservationScreen> createState() =>
      _EditObservationScreenState();
}

class _EditObservationScreenState extends State<EditObservationScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.observation.description,
    );
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La observación no puede estar vacía'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('observaciones')
        .doc(widget.observation.id)
        .update({
      'description': _controller.text, 
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar observación')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
