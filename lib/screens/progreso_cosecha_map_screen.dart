import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/cuartel.dart';
import '../services/firestore_service.dart';

class ProgresoCosechaMapScreen extends StatefulWidget {
  const ProgresoCosechaMapScreen({super.key});

  @override
  State<ProgresoCosechaMapScreen> createState() =>
      _ProgresoCosechaMapScreenState();
}

class _ProgresoCosechaMapScreenState extends State<ProgresoCosechaMapScreen> {
  final _firestore = FirestoreService();

  final Set<Polygon> _polygons = {};
  final Map<String, _CuartelProgress> _progress = {};

  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de cosecha')),
      body: StreamBuilder<List<Cuartel>>(
        stream: _firestore.getCuarteles(),
        builder: (context, snapshot) {
          final cuarteles = snapshot.data ?? [];

          if (cuarteles.isEmpty) {
            return const Center(child: Text('No hay cuarteles'));
          }

          return FutureBuilder<List<_CuartelProgress>>(
            future: _loadProgress(cuarteles),
            builder: (context, progressSnap) {
              if (!progressSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              _buildPolygons(cuarteles, progressSnap.data!);

              return Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.satellite,
                    initialCameraPosition: CameraPosition(
                      target: cuarteles.first.puntos.first,
                      zoom: 15,
                    ),
                    polygons: _polygons,
                    onMapCreated: (c) => _controller = c,
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _buildLegend(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_CuartelProgress>> _loadProgress(List<Cuartel> cuarteles) async {
    final futures = cuarteles.map(_computeCuartelProgress).toList();
    final list = await Future.wait(futures);
    return list;
  }

  Future<_CuartelProgress> _computeCuartelProgress(Cuartel c) async {
    final hileras = await FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(c.id)
        .collection('hileras')
        .get();

    int cosechadas = 0;
    int pendientes = 0;

    for (final h in hileras.docs) {
      final data = h.data();
      cosechadas += (data['cosechaCosechadas'] ?? 0) as int;
      pendientes += (data['cosechaPendientes'] ?? 0) as int;
    }

    final total = cosechadas + pendientes;
    final porcentaje = total == 0 ? 0.0 : (cosechadas / total) * 100;

    return _CuartelProgress(
      cuartel: c,
      cosechadas: cosechadas,
      pendientes: pendientes,
      porcentaje: porcentaje,
    );
  }

  void _buildPolygons(
    List<Cuartel> cuarteles,
    List<_CuartelProgress> progress,
  ) {
    _polygons.clear();
    _progress.clear();

    for (final p in progress) {
      _progress[p.cuartel.id] = p;

      _polygons.add(
        Polygon(
          polygonId: PolygonId(p.cuartel.id),
          points: p.cuartel.puntos,
          fillColor: _colorForPercent(p.porcentaje).withOpacity(0.35),
          strokeColor: _colorForPercent(p.porcentaje),
          strokeWidth: 3,
          consumeTapEvents: true,
          onTap: () => _showDetail(p),
        ),
      );
    }
  }

  Color _colorForPercent(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showDetail(_CuartelProgress p) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.cuartel.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Cosechadas: ${p.cosechadas}'),
            Text('Pendientes: ${p.pendientes}'),
            Text('Avance: ${p.porcentaje.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _LegendItem(color: Colors.green, label: '80-100%'),
            _LegendItem(color: Colors.orange, label: '40-79%'),
            _LegendItem(color: Colors.red, label: '0-39%'),
          ],
        ),
      ),
    );
  }
}

class _CuartelProgress {
  final Cuartel cuartel;
  final int cosechadas;
  final int pendientes;
  final double porcentaje;

  _CuartelProgress({
    required this.cuartel,
    required this.cosechadas,
    required this.pendientes,
    required this.porcentaje,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
