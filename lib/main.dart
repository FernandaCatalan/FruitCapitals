import 'package:flutter/material.dart';
import 'package:FruitCapitals/screens/empleado_home.dart';
import 'package:FruitCapitals/screens/jefe_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/theme.dart'; 
import 'package:flutter/services.dart';


import 'screens/register_screen.dart';
import 'screens/map_screen.dart';
import 'screens/acopio_home.dart';
import 'screens/login_screen.dart';

import 'package:provider/provider.dart';
import 'provider/theme_provider.dart';
import 'provider/auth_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final order = prefs.getString('order') ?? 'Recientes primero';
  final language = prefs.getString('language') ?? 'Español';

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()), 
      ],
      child: MyApp(
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(ThemeData.light().textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.light, 

      home: const RoleRouter(),
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(auth.user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginScreen();
        }

        final role = snapshot.data!.get('role');

        switch (role) {
          case 'jefe':
            return const JefeHome();
          case 'empleado':
            return const EmpleadoHome();
          case 'acopio':
            return const AcopioHome();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}

