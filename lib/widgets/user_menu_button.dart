import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cuartel.dart';
import '../screens/cuarteles_list_screen.dart';
import '../screens/hileras_screen.dart';

import '../provider/auth_provider.dart';

class UserMenuButton extends StatelessWidget {
  final bool showBackground;
  final Color? iconColor;
  final Color? backgroundColor;

  const UserMenuButton({
    super.key,
    this.showBackground = false,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.account_circle,
      color: iconColor ?? Theme.of(context).colorScheme.onSurface,
      size: 28,
    );

    final button = IconButton(
      tooltip: 'Usuario',
      icon: icon,
      onPressed: () => showUserMenu(context),
    );

    if (!showBackground) {
      return button;
    }

    return Material(
      elevation: 3,
      color: backgroundColor ?? Colors.white,
      shape: const CircleBorder(),
      child: button,
    );
  }
}

void showUserMenu(BuildContext context) {
  final user = fb.FirebaseAuth.instance.currentUser;
  final parentContext = context;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      if (user == null) {
        return _UserMenuContent(
          name: 'Sin sesion',
          email: '',
          role: null,
          onManageHileras: null,
          onSignOut: null,
        );
      }

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          String name = user.displayName ?? 'Usuario';
          String email = user.email ?? '';
          String? role;

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final docName = data?['name']?.toString().trim();
            final docEmail = data?['email']?.toString().trim();
            role = data?['role']?.toString().trim().toLowerCase();

            if (docName != null && docName.isNotEmpty) {
              name = docName;
            }
            if (docEmail != null && docEmail.isNotEmpty) {
              email = docEmail;
            }
          }

          return _UserMenuContent(
            name: name,
            email: email,
            role: role,
            onManageHileras: () async {
              Navigator.of(ctx).pop();
              Cuartel? selected;
              await Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (_) => CuartelesListScreen(
                    onCuartelSelected: (c) => selected = c,
                  ),
                ),
              );
              if (selected == null || !parentContext.mounted) return;
              await Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (_) => HilerasScreen(
                    cuartelId: selected!.id,
                    cuartelNombre: selected!.nombre,
                  ),
                ),
              );
            },
            onSignOut: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      );
    },
  );
}

class _UserMenuContent extends StatelessWidget {
  final String name;
  final String email;
  final String? role;
  final VoidCallback? onManageHileras;
  final Future<void> Function()? onSignOut;

  const _UserMenuContent({
    required this.name,
    required this.email,
    required this.role,
    required this.onManageHileras,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            if ((role ?? 'empleado') == 'empleado')
              ListTile(
                leading: const Icon(Icons.view_stream, color: Colors.green),
                title: const Text('Hileras y plantas'),
                onTap: onManageHileras,
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesion'),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
