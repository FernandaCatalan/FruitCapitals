import 'package:flutter/material.dart';

import 'entrega_screen.dart';
import 'map_screen.dart';
import 'observaciones_list_screen.dart';
import 'registro_cosecha_screen.dart';
import '../widgets/user_menu_button.dart';

class EmpleadoHome extends StatefulWidget {
  const EmpleadoHome({super.key});

  @override
  State<EmpleadoHome> createState() => _EmpleadoHomeState();
}

class _EmpleadoHomeState extends State<EmpleadoHome> {
  int _index = 0;

  final _pages = [
    const MapScreen(),
    const EntregaScreen(),
    ObservacionesListScreen(),
    const RegistroCosechaScreen(),
  ];

  final _items = const [
    _NavItem(icon: Icons.map, label: 'Mapa'),
    _NavItem(icon: Icons.add_box, label: 'Entrega'),
    _NavItem(icon: Icons.list, label: 'Obs.'),
    _NavItem(icon: Icons.agriculture, label: 'Cosecha'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    scheme.surfaceContainerLow,
                  ],
                ),
              ),
            ),
          ),
          IndexedStack(
            index: _index,
            children: _pages,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      isSelected: i == _index,
                      onTap: () => setState(() => _index = i),
                    ),
                  ),
                Expanded(
                  child: _ProfileNavButton(
                    onTap: () => showUserMenu(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isSelected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileNavButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _NavButton(
      item: const _NavItem(
        icon: Icons.account_circle,
        label: 'Perfil',
      ),
      isSelected: false,
      onTap: onTap,
    );
  }
}
