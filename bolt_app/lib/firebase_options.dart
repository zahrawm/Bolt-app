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
    apiKey: 'AIzaSyDUVMVjxdLS5HJpf0yXhXy_3OTThwcSULc',
    appId: '1:1061164939553:web:5ce8c1240ade21deb72660',
    messagingSenderId: '1061164939553',
    projectId: 'bolt-d1593',
    authDomain: 'bolt-d1593.firebaseapp.com',
    storageBucket: 'bolt-d1593.firebasestorage.app',
    measurementId: 'G-KXKY171LJW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOwF-OrvYljJ7qVIb27XQVX45zmh1AYgY',
    appId: '1:1061164939553:android:6b5a9feb9f802aa3b72660',
    messagingSenderId: '1061164939553',
    projectId: 'bolt-d1593',
    storageBucket: 'bolt-d1593.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATpKTAQQ42J-UkH3lQWK6FWNYsWg3JAko',
    appId: '1:1061164939553:ios:3a9084ba43a2e41db72660',
    messagingSenderId: '1061164939553',
    projectId: 'bolt-d1593',
    storageBucket: 'bolt-d1593.firebasestorage.app',
    iosBundleId: 'com.example.boltApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyATpKTAQQ42J-UkH3lQWK6FWNYsWg3JAko',
    appId: '1:1061164939553:ios:3a9084ba43a2e41db72660',
    messagingSenderId: '1061164939553',
    projectId: 'bolt-d1593',
    storageBucket: 'bolt-d1593.firebasestorage.app',
    iosBundleId: 'com.example.boltApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDUVMVjxdLS5HJpf0yXhXy_3OTThwcSULc',
    appId: '1:1061164939553:web:2e407ef11e91187fb72660',
    messagingSenderId: '1061164939553',
    projectId: 'bolt-d1593',
    authDomain: 'bolt-d1593.firebaseapp.com',
    storageBucket: 'bolt-d1593.firebasestorage.app',
    measurementId: 'G-LZ8HN6C1V4',
  );
}
