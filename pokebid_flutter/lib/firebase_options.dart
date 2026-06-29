// 此檔案由 FlutterFire CLI 自動生成
// 執行：flutterfire configure
// 詳見 README 或 Scope 文件中的 Firebase 設定步驟

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web push not configured yet.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  // ⚠️  以下為佔位值，執行 flutterfire configure 後會自動填入真實數值

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAwx5t7tY1-OFOGEPn5cPwke1EQtEx_61k',
    appId: '1:669585194614:android:aaaac13284eaa4a341e957',
    messagingSenderId: '669585194614',
    projectId: 'tcgspot-dc906',
    storageBucket: 'tcgspot-dc906.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAuNbwCm80gmIwAwkCiu8En70ikcK8M4HQ',
    appId: '1:669585194614:ios:408cb4346e705aec41e957',
    messagingSenderId: '669585194614',
    projectId: 'tcgspot-dc906',
    storageBucket: 'tcgspot-dc906.firebasestorage.app',
    iosBundleId: 'co.tcgspot.app',
  );
}
