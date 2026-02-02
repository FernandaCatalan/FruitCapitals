import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAMUOj8y1th0p9-Ti1a4XclVy-IiIPaE8Y',
    appId: '1:817688931018:web:da04663a0a9fcb87f7e233',
    messagingSenderId: '817688931018',
    projectId: 'fruit-capitals',
    authDomain: 'fruit-capitals.firebaseapp.com',
    storageBucket: 'fruit-capitals.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6J-yB9IOt_WRZ9Q3V55x_rj5v-c121nU',
    appId: '1:817688931018:android:6bece7bb0e5bc721f7e233',
    messagingSenderId: '817688931018',
    projectId: 'fruit-capitals',
    storageBucket: 'fruit-capitals.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2HYzSV1gZ3-fLpiSWM3X41Mhfl6cqkpI',
    appId: '1:817688931018:ios:646f0c4d89b04f88f7e233',
    messagingSenderId: '817688931018',
    projectId: 'fruit-capitals',
    storageBucket: 'fruit-capitals.firebasestorage.app',
    iosClientId: '817688931018-o9u6prkinhsnlmomsp5u0av13s9g9b0m.apps.googleusercontent.com',
    iosBundleId: 'com.example.fruitcapitals',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB2HYzSV1gZ3-fLpiSWM3X41Mhfl6cqkpI',
    appId: '1:817688931018:ios:646f0c4d89b04f88f7e233',
    messagingSenderId: '817688931018',
    projectId: 'fruit-capitals',
    storageBucket: 'fruit-capitals.firebasestorage.app',
    iosClientId: '817688931018-o9u6prkinhsnlmomsp5u0av13s9g9b0m.apps.googleusercontent.com',
    iosBundleId: 'com.example.fruitcapitals',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAMUOj8y1th0p9-Ti1a4XclVy-IiIPaE8Y',
    appId: '1:817688931018:web:318923765500932af7e233',
    messagingSenderId: '817688931018',
    projectId: 'fruit-capitals',
    authDomain: 'fruit-capitals.firebaseapp.com',
    storageBucket: 'fruit-capitals.firebasestorage.app',
  );
}
