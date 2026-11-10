import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXHquz0l7CDt_zx5qsrdMDQ1bxyzF1o0s',
    appId: '1:662923885492:android:c49802b4c0395e810690e1',
    messagingSenderId: '662923885492',
    projectId: 'dijlahapps2',
    storageBucket: 'dijlahapps2.firebasestorage.app',
  );
}

