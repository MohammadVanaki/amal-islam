import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXHquz0l7CDt_zx5qsrdMDQ1bxyzF1o0s',
    appId: '1:662923885492:android:c49802b4c0395e810690e1',
    messagingSenderId: '662923885492',
    projectId: 'dijlahapps2',
    storageBucket: 'dijlahapps2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjt6pg0YStnht0h2AoPjONSy45WKtCom8',
    appId: '1:662923885492:ios:e1d240ce636b43e90690e1',
    messagingSenderId: '662923885492',
    projectId: 'dijlahapps2',
    storageBucket: 'dijlahapps2.firebasestorage.app',
    iosBundleId: 'com.dijlah.alamalislam',
  );
}
