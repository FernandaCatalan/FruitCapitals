import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cuartel.dart';
import '../services/firestore_service.dart';

class CuartelesListScreen extends StatelessWidget {
  final void Function(Cuartel) onCuartelSelected;

  const CuartelesListScreen({
    super.key,
    required this.onCuartelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuarteles'),
      ),
      body: StreamBuilder<List<Cuartel>>(
        stream: FirestoreService().getCuarteles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final cuarteles = snapshot.data ?? [];

          if (cuarteles.isEmpty) {
            return const Center(
              child: Text('No hay cuarteles registrados'),
            );
          }

          return ListView.builder(
            itemCount: cuarteles.length,
            itemBuilder: (context, index) {
              final c = cuarteles[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    Icons.map,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    c.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${c.cultivo} · ${c.variedad}',
                  ),
                  onTap: () {
                    onCuartelSelected(c);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
