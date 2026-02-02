import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  User? _user;
  String? _userRole;

  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;

      if (user != null) {
        await _loadUserRole(user.uid);
      } else {
        _userRole = null;
      }

      notifyListeners();
    });
  }

  Future<void> _loadUserRole(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();

      if (snap.exists && snap.data()!.containsKey('role')) {
        _userRole = snap['role'];
        _logger.i("Rol cargado: $_userRole");
      } else {
        _userRole = null;
        _logger.w("⚠ Usuario sin rol en Firestore");
      }
    } catch (e) {
      _logger.e("Error cargando rol: $e");
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = _auth.currentUser?.uid;

      if (uid != null) {
        await _loadUserRole(uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String role) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        "email": email,
        "role": role,
      });

      await _loadUserRole(uid);

      _isLoading = false;
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userRole = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No existe una cuenta con este correo.';
      case 'wrong-password': return 'Contraseña incorrecta.';
      case 'email-already-in-use': return 'Este correo ya está registrado.';
      case 'invalid-email': return 'El correo no es válido.';
      case 'weak-password': return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests': return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed': return 'Error de conexión.';
      default: return 'Error: $code';
    }
  }
}