import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RolesEditorView extends StatelessWidget {
  const RolesEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Editar Roles",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.primary,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(child: Text("No hay usuarios registrados"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user["name"] ?? "Sin nombre";
              final email = user["email"] ?? "";
              final role = user["role"] ?? "worker";

              return ListTile(
                title: Text(name, style: theme.textTheme.bodyLarge),
                subtitle: Text("$email\nRol actual: $role",
                    style: theme.textTheme.bodyMedium),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.edit, color: colors.primary),
                  onSelected: (newRole) {
                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.id)
                        .update({"role": newRole});
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "dueño", child: Text("Dueño")),
                    const PopupMenuItem(value: "planillero", child: Text("Planillero")),
                    const PopupMenuItem(value: "jefe_packing", child: Text("Jefe de packing")),
                    const PopupMenuItem(value: "jefe_cuadrilla", child: Text("Jefe de cuadrilla")),
                    const PopupMenuItem(value: "contratista", child: Text("Contratista")),
                    const PopupMenuItem(value: "none", child: Text("Sin rol")),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}