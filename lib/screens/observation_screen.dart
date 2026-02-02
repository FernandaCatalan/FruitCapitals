import 'package:flutter/material.dart';

import '../models/cuartel.dart';
import 'comentario_mata_screen.dart';
import 'cuarteles_list_screen.dart';
import 'registro_dardos_screen.dart';
import 'registro_flores_screen.dart';
import 'registros_frutos_flor_screen.dart';
import 'seleccionar_hilera_screen.dart';
import 'seleccionar_mata_screen.dart';

class ObservationScreen extends StatefulWidget {
  const ObservationScreen({super.key});

  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> {
  Future<_SeleccionMata?> _selectMata() async {
    Cuartel? cuartel;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CuartelesListScreen(
          onCuartelSelected: (c) => cuartel = c,
        ),
      ),
    );

    if (!mounted || cuartel == null) return null;

    final hilera = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarHileraScreen(
          cuartelId: cuartel!.id,
          cuartelNombre: cuartel!.nombre,
        ),
      ),
    );

    if (!mounted || hilera == null) return null;

    final mata = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarMataScreen(
          cuartelId: cuartel!.id,
          cuartelNombre: cuartel!.nombre,
          hileraId: hilera['id'] as String,
          numeroHilera: hilera['numero'] as int,
        ),
      ),
    );

    if (!mounted || mata == null) return null;

    return _SeleccionMata(
      cuartelId: cuartel!.id,
      cuartelNombre: cuartel!.nombre,
      hileraId: hilera['id'] as String,
      numeroHilera: hilera['numero'] as int,
      mataId: mata['id'] as String,
      numeroMata: mata['numero'] as int,
    );
  }

  Future<void> _startConteoDardos() async {
    final selection = await _selectMata();
    if (selection == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroDardosScreen(
          cuartelId: selection.cuartelId,
          cuartelNombre: selection.cuartelNombre,
          hileraId: selection.hileraId,
          numeroHilera: selection.numeroHilera,
          mataId: selection.mataId,
          numeroMata: selection.numeroMata,
        ),
      ),
    );
  }

  Future<void> _startConteoFlores() async {
    final selection = await _selectMata();
    if (selection == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroFloresScreen(
          mataId: selection.mataId,
          cuartelId: selection.cuartelId,
          hileraId: selection.hileraId,
        ),
      ),
    );
  }

  Future<void> _startConteoFrutos() async {
    final selection = await _selectMata();
    if (selection == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroFrutosFlorScreen(
          mataId: selection.mataId,
          cuartelId: selection.cuartelId,
          hileraId: selection.hileraId,
        ),
      ),
    );
  }

  Future<void> _startComentarioMata() async {
    final selection = await _selectMata();
    if (selection == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComentarioMataScreen(
          cuartelId: selection.cuartelId,
          cuartelNombre: selection.cuartelNombre,
          hileraId: selection.hileraId,
          numeroHilera: selection.numeroHilera,
          mataId: selection.mataId,
          numeroMata: selection.numeroMata,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Guardar informacion del registro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            title: 'Conteo de dardos',
            subtitle: 'Registra el total de dardos en una planta',
            icon: Icons.grain,
            iconColor: scheme.primary,
            onTap: _startConteoDardos,
          ),
          _ActionCard(
            title: 'Conteo de flores',
            subtitle: 'Selecciona un dardo y registra cuantas flores',
            icon: Icons.local_florist,
            iconColor: scheme.primary,
            onTap: _startConteoFlores,
          ),
          _ActionCard(
            title: 'Conteo de frutos por flor',
            subtitle: 'Selecciona una flor y registra cuantos frutos',
            icon: Icons.apple,
            iconColor: scheme.primary,
            onTap: _startConteoFrutos,
          ),
          _ActionCard(
            title: 'Comentario de planta anomala',
            subtitle: 'Guarda un comentario y/o fotos de la planta',
            icon: Icons.report_problem,
            iconColor: scheme.primary,
            onTap: _startComentarioMata,
          ),
        ],
      ),
    );
  }
}

class _SeleccionMata {
  final String cuartelId;
  final String cuartelNombre;
  final String hileraId;
  final int numeroHilera;
  final String mataId;
  final int numeroMata;

  _SeleccionMata({
    required this.cuartelId,
    required this.cuartelNombre,
    required this.hileraId,
    required this.numeroHilera,
    required this.mataId,
    required this.numeroMata,
  });
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
