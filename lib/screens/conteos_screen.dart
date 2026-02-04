import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _exporting = false;

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

  String _safeFileName(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _safeSheetName(String raw, {int maxLen = 31}) {
    var value = raw.replaceAll(RegExp(r'[:\\\\/?*\\[\\]]'), '_').trim();
    if (value.isEmpty) value = 'Cuartel';
    if (value.length > maxLen) {
      value = value.substring(0, maxLen);
    }
    return value;
  }

  Future<List<_ConteoDardoExportRow>> _buildExportRowsForCuartel({
    required String cuartelId,
    required String cuartelNombre,
  }) async {
    final hilerasSnap = await FirebaseFirestore.instance
        .collection('cuarteles')
        .doc(cuartelId)
        .collection('hileras')
        .orderBy('numero')
        .get();

    Map<int, int> parseDardosPorYema(dynamic rawMap) {
      final parsed = <int, int>{};
      if (rawMap is! Map) return parsed;
      rawMap.forEach((key, value) {
        final k = int.tryParse(key.toString());
        final v = _parseInt(value);
        if (k != null && k >= 3 && k <= 10) {
          parsed[k] = v;
        }
      });
      return parsed;
    }

    _ConteoDardoExportRow toRow({
      required int numeroHilera,
      required int numeroMata,
      required Map<String, dynamic> data,
    }) {
      final dardosPorYema = parseDardosPorYema(data['dardosPorYema']);
      final total = dardosPorYema.values.fold<int>(0, (a, b) => a + b);
      final totalDardos = total > 0 ? total : _parseInt(data['cantidadDardos']);
      return _ConteoDardoExportRow(
        cuartelNombre: cuartelNombre,
        numeroHilera: numeroHilera,
        numeroMata: numeroMata,
        dardosPorYema: dardosPorYema,
        cantidadDardos: totalDardos,
        ramillas: _parseInt(data['ramillas']),
      );
    }

    final rowsByHilera = await Future.wait(
      hilerasSnap.docs.map((hileraDoc) async {
        final numeroHilera = _parseInt(hileraDoc.data()['numero']);
        final matasSnap = await hileraDoc.reference
            .collection('matas')
            .orderBy('numero')
            .get();

        final rowsByMata = await Future.wait(
          matasSnap.docs.map((mataDoc) async {
            final numeroMata = _parseInt(mataDoc.data()['numero']);
            final mataData = mataDoc.data();
            final ultimo = mataData['ultimoConteoDardos'];
            if (ultimo is Map) {
              final ultimoData = Map<String, dynamic>.from(ultimo);
              return toRow(
                numeroHilera: numeroHilera,
                numeroMata: numeroMata,
                data: ultimoData,
              );
            }

            final conteoSnap = await mataDoc.reference
                .collection('conteo_dardos')
                .orderBy('fecha', descending: true)
                .limit(1)
                .get();
            if (conteoSnap.docs.isEmpty) return null;

            return toRow(
              numeroHilera: numeroHilera,
              numeroMata: numeroMata,
              data: conteoSnap.docs.first.data(),
            );
          }),
        );

        return rowsByMata.whereType<_ConteoDardoExportRow>().toList();
      }),
    );

    return rowsByHilera.expand((e) => e).toList();
  }

  Future<void> _exportarDardosExcel({
    String? cuartelId,
    Cuartel? cuartel,
  }) async {
    final exportAll = cuartelId == null;
    if (!exportAll && cuartel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona un cuartel para exportar'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final excel = Excel.createExcel();
      if (exportAll) {
        final cuarteles = await _firestore.getCuarteles().first;
        final rowsPorCuartel = await Future.wait(
          cuarteles.map((c) {
            return _buildExportRowsForCuartel(
              cuartelId: c.id,
              cuartelNombre: c.nombre,
            );
          }),
        );
        final usedSheetNames = <String>{};
        var firstSheet = true;
        var hasData = false;
        for (int idx = 0; idx < cuarteles.length; idx++) {
          final c = cuarteles[idx];
          final rows = rowsPorCuartel[idx];
          if (rows.isEmpty) continue;
          hasData = true;
          rows.sort((a, b) {
            final h = a.numeroHilera.compareTo(b.numeroHilera);
            if (h != 0) return h;
            return a.numeroMata.compareTo(b.numeroMata);
          });

          var base = _safeSheetName(c.nombre);
          var name = base;
          var i = 2;
          while (usedSheetNames.contains(name)) {
            final suffix = '_$i';
            final cut = (base.length + suffix.length > 31)
                ? base.substring(0, 31 - suffix.length)
                : base;
            name = '$cut$suffix';
            i++;
          }
          usedSheetNames.add(name);

          if (firstSheet) {
            excel.rename('Sheet1', name);
            firstSheet = false;
          }
          final Sheet sheet = excel[name];

          sheet.appendRow([TextCellValue('Cuartel: ${c.nombre}')]);
          sheet.appendRow([]);
          sheet.appendRow([
            TextCellValue('Hilera'),
            TextCellValue('Planta'),
            TextCellValue('3'),
            TextCellValue('4'),
            TextCellValue('5'),
            TextCellValue('6'),
            TextCellValue('7'),
            TextCellValue('8'),
            TextCellValue('9'),
            TextCellValue('10'),
            TextCellValue('Total'),
            TextCellValue('Ramillas'),
          ]);

          for (final row in rows) {
            sheet.appendRow([
              IntCellValue(row.numeroHilera),
              IntCellValue(row.numeroMata),
              IntCellValue(row.dardosPorYema[3] ?? 0),
              IntCellValue(row.dardosPorYema[4] ?? 0),
              IntCellValue(row.dardosPorYema[5] ?? 0),
              IntCellValue(row.dardosPorYema[6] ?? 0),
              IntCellValue(row.dardosPorYema[7] ?? 0),
              IntCellValue(row.dardosPorYema[8] ?? 0),
              IntCellValue(row.dardosPorYema[9] ?? 0),
              IntCellValue(row.dardosPorYema[10] ?? 0),
              IntCellValue(row.cantidadDardos),
              IntCellValue(row.ramillas),
            ]);
          }
        }

        if (!hasData) {
          throw Exception('No hay plantas con conteo de dardos');
        }
      } else {
        final selectedCuartel = cuartel!;
        final rows = await _buildExportRowsForCuartel(
          cuartelId: cuartelId,
          cuartelNombre: selectedCuartel.nombre,
        );
        if (rows.isEmpty) {
          throw Exception('No hay plantas con conteo de dardos en este cuartel');
        }
        rows.sort((a, b) {
          final h = a.numeroHilera.compareTo(b.numeroHilera);
          if (h != 0) return h;
          return a.numeroMata.compareTo(b.numeroMata);
        });

        const sheetName = 'Conteo dardos';
        excel.rename('Sheet1', sheetName);
        final Sheet sheet = excel[sheetName];
        sheet.appendRow([TextCellValue('Cuartel: ${selectedCuartel.nombre}')]);
        sheet.appendRow([]);
        sheet.appendRow([
          TextCellValue('Hilera'),
          TextCellValue('Planta'),
          TextCellValue('3'),
          TextCellValue('4'),
          TextCellValue('5'),
          TextCellValue('6'),
          TextCellValue('7'),
          TextCellValue('8'),
          TextCellValue('9'),
          TextCellValue('10'),
          TextCellValue('Total'),
          TextCellValue('Ramillas'),
        ]);

        for (final row in rows) {
          sheet.appendRow([
            IntCellValue(row.numeroHilera),
            IntCellValue(row.numeroMata),
            IntCellValue(row.dardosPorYema[3] ?? 0),
            IntCellValue(row.dardosPorYema[4] ?? 0),
            IntCellValue(row.dardosPorYema[5] ?? 0),
            IntCellValue(row.dardosPorYema[6] ?? 0),
            IntCellValue(row.dardosPorYema[7] ?? 0),
            IntCellValue(row.dardosPorYema[8] ?? 0),
            IntCellValue(row.dardosPorYema[9] ?? 0),
            IntCellValue(row.dardosPorYema[10] ?? 0),
            IntCellValue(row.cantidadDardos),
            IntCellValue(row.ramillas),
          ]);
        }
      }

      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('No se pudo generar el archivo Excel');
      }

      final dir = await getTemporaryDirectory();
      final fileName = exportAll
          ? 'conteo_dardos_todos_los_cuarteles.xlsx'
          : 'conteo_dardos_${_safeFileName(cuartel!.nombre)}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: exportAll
            ? 'Conteo de dardos por planta - Todos los cuarteles'
            : 'Conteo de dardos por planta - ${cuartel!.nombre}',
        subject: exportAll
            ? 'Conteo de dardos - Todos los cuarteles'
            : 'Conteo de dardos ${cuartel!.nombre}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _mostrarOpcionesExportacion() async {
    if (_exporting) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.filter_alt),
                  title: const Text('Exportar cuartel seleccionado'),
                  subtitle: const Text('Solo requiere elegir cuartel'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportarDardosExcel(cuartelId: _cuartelId, cuartel: _cuartel);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Exportar todos los cuarteles'),
                  subtitle: const Text('Archivo general'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportarDardosExcel();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteos'),
        actions: [
          IconButton(
            tooltip: 'Exportar Excel de dardos',
            onPressed: _exporting ? null : _mostrarOpcionesExportacion,
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
          ),
        ],
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
                    final ramillas = _parseInt(data['ramillas']);
                    final rawMap = data['dardosPorYema'];
                    String detalle = '';
                    if (rawMap is Map) {
                      final parts = <String>[];
                      for (final entry in rawMap.entries) {
                        parts.add('${entry.key}y: ${entry.value}');
                      }
                      parts.sort();
                      if (parts.isNotEmpty) {
                        detalle = ' (${parts.join(', ')})';
                      }
                    }
                    final ts = data['fecha'] as Timestamp?;
                    return _RowItem(
                      title: 'Cantidad: $count$detalle · Ramillas: $ramillas',
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

class _ConteoDardoExportRow {
  final String cuartelNombre;
  final int numeroHilera;
  final int numeroMata;
  final Map<int, int> dardosPorYema;
  final int cantidadDardos;
  final int ramillas;

  const _ConteoDardoExportRow({
    required this.cuartelNombre,
    required this.numeroHilera,
    required this.numeroMata,
    required this.dardosPorYema,
    required this.cantidadDardos,
    required this.ramillas,
  });
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
