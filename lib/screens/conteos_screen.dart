import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cuartel.dart';
import '../models/conteoflores.dart';
import '../models/frutoflor.dart';
import '../services/firestore_service.dart';
import '../services/floracion_service.dart';

class ConteosScreen extends StatefulWidget {
  const ConteosScreen({super.key});

  @override
  State<ConteosScreen> createState() => _ConteosScreenState();
}

class _ConteosScreenState extends State<ConteosScreen> {
  final _firestore = FirestoreService();
  final _floracion = FloracionService();
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  Cuartel? _cuartel;
  String? _cuartelId;
  String? _hileraId;
  int? _numeroHilera;
  String? _mataId;
  int? _numeroPlanta;
  String? _dardoId;
  int? _dardoNumero;

  void _resetFromCuartel() {
    _hileraId = null;
    _numeroHilera = null;
    _mataId = null;
    _numeroPlanta = null;
    _dardoId = null;
    _dardoNumero = null;
  }

  void _resetFromHilera() {
    _mataId = null;
    _numeroPlanta = null;
    _dardoId = null;
    _dardoNumero = null;
  }

  void _resetFromMata() {
    _dardoId = null;
    _dardoNumero = null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _hilerasStream() {
    return FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(_cuartelId)
        .collection('hileras')
        .orderBy('numero')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _matasStream() {
    return FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(_cuartelId)
        .collection('hileras')
        .doc(_hileraId)
        .collection('matas')
        .orderBy('numero')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _dardosStream() {
    return _floracion.getDardosPorMataQuery(
      cuartelId: _cuartelId!,
      hileraId: _hileraId!,
      mataId: _mataId!,
    );
  }

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFiltersCard(theme),
          const SizedBox(height: 12),
          if (_dardoId != null) _buildDetalleDardo(theme),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Cuartel>>(
              stream: _firestore.getCuarteles(),
              builder: (context, snapshot) {
                final cuarteles = snapshot.data ?? [];
                final ids = cuarteles.map((c) => c.id).toSet();
                final selectedId = ids.contains(_cuartelId) ? _cuartelId : null;

                return DropdownButtonFormField<String>(
                  value: selectedId,
                  items: cuarteles
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    final selected = cuarteles.firstWhere((c) => c.id == id);
                    setState(() {
                      _cuartelId = id;
                      _cuartel = selected;
                      _resetFromCuartel();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Cuartel',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_cuartelId != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _hilerasStream(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No hay hileras registradas',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    );
                  }
                  final ids = docs.map((d) => d.id).toSet();
                  final selectedId = ids.contains(_hileraId) ? _hileraId : null;

                  return DropdownButtonFormField<String>(
                    value: selectedId,
                    items: docs
                        .map((d) {
                          final numero = _parseInt(d.data()['numero']);
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text('Hilera $numero'),
                          );
                        })
                        .toList(),
                    onChanged: (v) {
                      final numero = docs
                          .firstWhere((d) => d.id == v)
                          .data()['numero'];
                      setState(() {
                        _hileraId = v;
                        _numeroHilera = _parseInt(numero);
                        _resetFromHilera();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Hilera',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            if (_hileraId != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _matasStream(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No hay plantas registradas',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    );
                  }
                  final ids = docs.map((d) => d.id).toSet();
                  final selectedId = ids.contains(_mataId) ? _mataId : null;

                  return DropdownButtonFormField<String>(
                    value: selectedId,
                    items: docs
                        .map((d) {
                          final numero = _parseInt(d.data()['numero']);
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text('Planta $numero'),
                          );
                        })
                        .toList(),
                    onChanged: (v) {
                      final numero = docs
                          .firstWhere((d) => d.id == v)
                          .data()['numero'];
                      setState(() {
                        _mataId = v;
                        _numeroPlanta = _parseInt(numero);
                        _resetFromMata();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Planta',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            if (_mataId != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _dardosStream(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No hay dardos registrados',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    );
                  }
                  final ids = docs.map((d) => d.id).toSet();
                  final selectedId = ids.contains(_dardoId) ? _dardoId : null;

                  return DropdownButtonFormField<String>(
                    value: selectedId,
                    items: docs
                        .map((d) {
                          final numero = _parseInt(d.data()['numero']);
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text('Dardo $numero'),
                          );
                        })
                        .toList(),
                    onChanged: (v) {
                      final numero = docs
                          .firstWhere((d) => d.id == v)
                          .data()['numero'];
                      setState(() {
                        _dardoId = v;
                        _dardoNumero = _parseInt(numero);
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Dardo',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleDardo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.grain),
            title: Text('Dardo $_dardoNumero'),
            subtitle: Text(
              'Cuartel ${_cuartel?.nombre} · Hilera $_numeroHilera · Planta $_numeroPlanta',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildConteoDardos(theme),
        const SizedBox(height: 12),
        _buildConteoFlores(theme),
        const SizedBox(height: 12),
        _buildFrutosPorFlor(theme),
      ],
    );
  }

  Widget _buildConteoDardos(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _floracion.getConteosDardosQuery(
        cuartelId: _cuartel!.id,
        hileraId: _hileraId!,
        mataId: _mataId!,
      ),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return _SectionCard(
          title: 'Historial de conteo de dardos',
          icon: Icons.grain,
          child: docs.isEmpty
              ? const Text('Sin registros')
              : Column(
                  children: docs.map((d) {
                    final data = d.data();
                    final count = data['cantidadDardos'] ?? 0;
                    final ts = data['fecha'] as Timestamp?;
                    return _RowItem(
                      title: 'Cantidad: $count',
                      subtitle: ts == null ? 'Sin fecha' : _dateFmt.format(ts.toDate()),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildConteoFlores(ThemeData theme) {
    return StreamBuilder<List<ConteoFlores>>(
      stream: _floracion.getConteosFlores(
        cuartelId: _cuartel!.id,
        hileraId: _hileraId!,
        mataId: _mataId!,
        dardoId: _dardoId!,
      ),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return _SectionCard(
          title: 'Historial de conteo de flores',
          icon: Icons.local_florist,
          child: items.isEmpty
              ? const Text('Sin registros')
              : Column(
                  children: items.map((c) {
                    return _RowItem(
                      title: 'Total: ${c.totalFlores}',
                      subtitle: _dateFmt.format(c.fecha),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildFrutosPorFlor(ThemeData theme) {
    return StreamBuilder<List<FrutoFlor>>(
      stream: _floracion.getFrutosPorFlor(
        cuartelId: _cuartel!.id,
        hileraId: _hileraId!,
        mataId: _mataId!,
        dardoId: _dardoId!,
      ),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return _SectionCard(
          title: 'Historial de frutos por flor',
          icon: Icons.apple,
          child: items.isEmpty
              ? const Text('Sin registros')
              : Column(
                  children: items.map((c) {
                    return _RowItem(
                      title: 'Flor ${c.florNumero} · Frutos ${c.cantidadFrutos}',
                      subtitle: _dateFmt.format(c.fecha),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RowItem({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
