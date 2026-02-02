import 'package:flutter/material.dart';
import 'package:FruitCapitals/screens/map_screen.dart';
import 'package:FruitCapitals/screens/observaciones_list_screen.dart';
import 'package:FruitCapitals/screens/conteos_screen.dart';
import 'package:FruitCapitals/screens/progreso_cosecha_map_screen.dart';
import 'package:FruitCapitals/screens/pago_config_screen.dart';
import 'package:FruitCapitals/screens/reporte_pagos_screen.dart';
import 'package:FruitCapitals/screens/reporte_fruta_screen.dart';
import 'package:FruitCapitals/screens/reporte_descuentos_screen.dart';
import 'package:FruitCapitals/screens/cuarteles_list_screen.dart';

import 'heatmap_screen.dart';
import 'stats_screen.dart';
import '../widgets/user_menu_button.dart';

class JefeHome extends StatefulWidget {
  const JefeHome({super.key});

  @override
  State<JefeHome> createState() => _JefeHomeState();
}

class _JefeHomeState extends State<JefeHome> {
  int _index = 0;

  late final List<_JefePage> _pages = [
    _JefePage(
      title: 'Mapa',
      subtitle: 'Cuarteles y capas',
      icon: Icons.map,
      page: const MapScreen(showNuevaObservacion: false),
    ),
    _JefePage(
      title: 'Heatmap',
      subtitle: 'Mapa de calor',
      icon: Icons.local_fire_department,
      page: HeatMapScreen(),
    ),
    _JefePage(
      title: 'Stats',
      subtitle: 'Entregas y tendencias',
      icon: Icons.bar_chart,
      page: StatsScreen(),
    ),
    _JefePage(
      title: 'Observaciones',
      subtitle: 'Registros de campo',
      icon: Icons.list,
      page: ObservacionesListScreen(),
    ),
    _JefePage(
      title: 'Conteos',
      subtitle: 'Dardos, flores y frutos',
      icon: Icons.grain,
      page: ConteosScreen(),
    ),
    _JefePage(
      title: 'Cosecha',
      subtitle: 'Avance por cuartel',
      icon: Icons.agriculture,
      page: ProgresoCosechaMapScreen(),
    ),
    _JefePage(
      title: 'Pago',
      subtitle: 'Configurar parámetros',
      icon: Icons.settings,
      page: const PagoConfigScreen(),
    ),
    _JefePage(
      title: 'Pagos',
      subtitle: 'Reporte de pagos',
      icon: Icons.payments,
      page: const ReportePagosScreen(),
    ),
    _JefePage(
      title: 'Fruta',
      subtitle: 'Producción por contratista',
      icon: Icons.inventory_2,
      page: const ReporteFrutaScreen(),
    ),
    _JefePage(
      title: 'Devoluciones',
      subtitle: 'Descuentos y motivos',
      icon: Icons.assignment_return,
      page: const ReporteDescuentosScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_index].title),
        toolbarHeight: _index == 0 ? 48 : null,
      ),
      drawer: _buildDrawer(context),
      body: _pages[_index].page,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.only(top: 0),
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16 + MediaQuery.of(context).padding.top,
              16,
              12,
            ),
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.agriculture,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 36,
                    ),
                    UserMenuButton(
                      showBackground: true,
                      iconColor: Theme.of(context).colorScheme.onPrimary,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Panel Jefe',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Navegacion',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          _SectionTitle(text: 'Operación'),
          _DrawerItem(
            page: _pages[0],
            selected: _index == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _index = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Cuarteles'),
            subtitle: const Text('Listado y detalle'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CuartelesListScreen(
                    onCuartelSelected: (_) {},
                  ),
                ),
              );
            },
          ),
          for (int i = 1; i <= 5; i++)
            _DrawerItem(
              page: _pages[i],
              selected: _index == i,
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = i);
              },
            ),
          const Divider(height: 24),
          _SectionTitle(text: 'Administración'),
          _DrawerItem(
            page: _pages[6],
            selected: _index == 6,
            onTap: () {
              Navigator.pop(context);
              setState(() => _index = 6);
            },
          ),
          const Divider(height: 24),
          _SectionTitle(text: 'Reportes'),
          for (int i = 7; i < _pages.length; i++)
            _DrawerItem(
              page: _pages[i],
              selected: _index == i,
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = i);
              },
            ),
        ],
      ),
    );
  }
}

class _JefePage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  const _JefePage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}

class _DrawerItem extends StatelessWidget {
  final _JefePage page;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(page.icon),
      title: Text(page.title),
      subtitle: Text(page.subtitle),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primary,
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
