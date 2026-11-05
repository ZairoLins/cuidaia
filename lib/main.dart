import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/assistente_gemini.dart';
import 'firebase_options.dart';
import 'services/conta_firebase.dart';
import 'state/app_state.dart';

/// Chave do site reCAPTCHA v3 para o App Check na versão web:
/// `flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=...`
const _recaptchaWeb = String.fromEnvironment('RECAPTCHA_SITE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ativarAppCheck();

  final estado = await AppState.carregar(conta: ContaFirebase(), novoAssistente: AssistenteGemini.new);
  runApp(CuidaApp(estado: estado));
}

/// O App Check impede que outros apps usem a cota da IA do projeto.
/// Em modo debug, o token de depuração aparece no console: cadastre-o em
/// Firebase Console > App Check > Apps > Gerenciar tokens de depuração.
Future<void> _ativarAppCheck() async {
  if (kIsWeb && _recaptchaWeb.isEmpty) {
    debugPrint('App Check desativado na web: defina RECAPTCHA_SITE_KEY.');
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? ReCaptchaV3Provider(_recaptchaWeb) : null,
      providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestProvider(),
    );
  } catch (e) {
    debugPrint('App Check não ativado: $e');
  }
}
