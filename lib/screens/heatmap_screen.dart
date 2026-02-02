import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/entrega.dart';
import '../services/firestore_service.dart';

class HeatMapScreen extends StatelessWidget {
  HeatMapScreen({super.key});

  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de calor de entregas')),
      body: StreamBuilder<List<Entrega>>(
        stream: _firestore.getEntregas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay entregas registradas',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final entregas = snapshot.data!;
          final first = entregas.first;

          final circles = entregas.map((e) {
            return Circle(
              circleId: CircleId(e.id),
              center: LatLng(e.lat, e.lng),
              radius: 80, 
              fillColor: _heatColor(e.cantidad),
              strokeWidth: 0,
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(first.lat, first.lng),
              zoom: 15,
            ),
            circles: circles,
          );
        },
      ),
    );
  }

  Color _heatColor(double cantidad) {
    if (cantidad < 30) {
      return Colors.blue.withOpacity(0.35);
    } else if (cantidad < 70) {
      return Colors.yellow.withOpacity(0.45);
    } else if (cantidad < 120) {
      return Colors.orange.withOpacity(0.55);
    } else {
      return Colors.red.withOpacity(0.7);
    }
  }
}
