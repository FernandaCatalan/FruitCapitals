import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/reporte_zona_service.dart';

class ReporteZonaScreen extends StatefulWidget {
  const ReporteZonaScreen({super.key});

  @override
  State<ReporteZonaScreen> createState() => _ReporteZonaScreenState();
}

class _ReporteZonaScreenState extends State<ReporteZonaScreen> {
  final ReporteZonaService _reporteService = ReporteZonaService();

  bool _loading = false;

  Future<void> _exportarExcel() async {
    setState(() => _loading = true);

    try {
      final File file = await _reporteService.generarReportePorZona();

      if (!mounted) return;

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: 'Reporte de entregas por cuartel',
        subject: 'Reporte por Zona',
      );
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
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte por Zona'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporte de entregas por cuartel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera y comparte un archivo Excel con el total de kilos por zona.',
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_download),
                label: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Exportar y compartir Excel'),
                onPressed: _loading ? null : _exportarExcel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

