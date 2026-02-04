import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/floracion_service.dart';
import 'crear_dardo_screen.dart';
import 'dardo_detalle_screen.dart';

class DardosScreen extends StatefulWidget {
  final String cuartelId;
  final String cuartelNombre;
  final String hileraId;
  final int numeroHilera;
  final String mataId;
  final int numeroMata;

  const DardosScreen({
    super.key,
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hileraId,
    required this.numeroHilera,
    required this.mataId,
    required this.numeroMata,
  });

  @override
  State<DardosScreen> createState() => _DardosScreenState();
}

class _DardosScreenState extends State<DardosScreen> {
  final FloracionService _service = FloracionService();
  bool _canCreateDardo = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final role = await FirestoreService().getUserRole(uid);
    if (!mounted) return;

    final r = role.toLowerCase();
    setState(() {
      _canCreateDardo = !r.startsWith('jefe');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dardos – Planta ${widget.numeroMata} (Hilera ${widget.numeroHilera})'),
      ),
      body: StreamBuilder(
        stream: _service.getDardos(
          cuartelId: widget.cuartelId,
          hileraId: widget.hileraId,
          mataId: widget.mataId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dardos = snapshot.data!;
          if (dardos.isEmpty) {
            return Center(
              child: Text(
                'No hay dardos registrados',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: dardos.length,
            itemBuilder: (_, i) {
              final d = dardos[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.grain),
                  title: Text('Dardo ${d.numero}'),
                  subtitle: Text('ID: ${d.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DardoDetalleScreen(
                          cuartelId: widget.cuartelId,
                          cuartelNombre: widget.cuartelNombre,
                          hileraId: widget.hileraId,
                          numeroHilera: widget.numeroHilera,
                          mataId: widget.mataId,
                          numeroMata: widget.numeroMata,
                          dardoId: d.id,
                          dardoNumero: d.numero,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _canCreateDardo
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Crear dardo'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CrearDardoScreen(
                      cuartelId: widget.cuartelId,
                      hileraId: widget.hileraId,
                      mataId: widget.mataId,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}
