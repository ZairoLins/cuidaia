// Arquivo provisório. Ele será substituído ao rodar:
//
//   flutterfire configure --project=<id-do-projeto>
//
// (veja "Configurar o Firebase" no README).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase ainda não configurado. Rode "flutterfire configure" (veja o README).',
      );
}
