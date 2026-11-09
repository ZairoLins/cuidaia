import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/assistente_gemini.dart';
import 'data/conteudos.dart';
import 'firebase_options.dart';
import 'screens/artigo_screen.dart';
import 'services/conta_firebase.dart';
import 'services/lembretes.dart';
import 'state/app_state.dart';

/// Chave do site do Fraud Defense (antigo reCAPTCHA Enterprise) para o
/// App Check na versão web. O reCAPTCHA v3 clássico não é mais aceito.
/// A chave do site é pública (fica visível na página), por isso pode ficar
/// no código. Para usar outra: `--dart-define=RECAPTCHA_SITE_KEY=...`
const _recaptchaWeb = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY',
  defaultValue: '6LdoEhguAAAAAEu_bGojbbP5SNRR8pVahQQH9m_L',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ativarAppCheck();

  late final AppState estado;
  final lembretes = LembretesLocais.instancia;
  String? abertura;
  try {
    abertura = await lembretes.iniciar(aoTocar: (payload) => _abrirLembrete(estado, payload));
  } catch (e) {
    debugPrint('Lembretes não iniciados: $e');
  }

  estado = await AppState.carregar(
    conta: ContaFirebase(),
    novoAssistente: AssistenteGemini.new,
    lembretes: lembretes.disponivel ? lembretes : const LembretesDesligados(),
  );
  runApp(CuidaApp(estado: estado));
  if (abertura != null) {
    final payload = abertura;
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirLembrete(estado, payload));
  }
}

/// Toque no lembrete "Continuar leitura": abre o artigo. A dica semanal só abre o app.
void _abrirLembrete(AppState estado, String payload) {
  if (!estado.logado || !payload.startsWith('leitura:')) return;
  final topico = payload.substring('leitura:'.length);
  final artigo = artigos[topico];
  if (artigo == null) return;
  estado.leituraIniciada(topico: topico, titulo: artigo.titulo);
  CuidaApp.navegador.currentState?.push(MaterialPageRoute(builder: (_) => ArtigoScreen(topico: topico)));
}

/// Token de depuração fixo, opcional. Sem ele, o Firebase gera um token por
/// navegador/aparelho e mostra no console. Nunca coloque o valor no código:
/// `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<token>`
const _tokenDepuracao = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
const _tokenAvaliacao = String.fromEnvironment('APP_CHECK_TOKEN_AVALIACAO');

/// O App Check impede que outros apps usem a cota da IA do projeto.
///
/// Em modo debug (`flutter run`), todas as plataformas usam o provedor de
/// depuração: o token aparece no console (na web, no console do navegador, F12)
/// e deve ser cadastrado em Firebase Console > App Check > Apps >
/// Gerenciar tokens de depuração. Na versão publicada: Fraud Defense (web),
/// Play Integrity (Android) e App Attest (iOS).
///
/// APK de avaliação (para a banca, fora da Play Store): o Play Integrity só
/// aprova apps baixados da loja, então esse APK usa um token de depuração
/// próprio, separado do de desenvolvimento, que pode ser revogado no console
/// depois da avaliação: `--dart-define-from-file=app_check.avaliacao.local.json`.
Future<void> _ativarAppCheck() async {
  final token = _tokenDepuracao.isEmpty ? null : _tokenDepuracao;
  final depuracao = kDebugMode || _tokenAvaliacao.isNotEmpty;
  final tokenUsado = _tokenAvaliacao.isNotEmpty ? _tokenAvaliacao : token;
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: !kIsWeb
          ? null
          : depuracao
          ? WebDebugProvider(debugToken: tokenUsado)
          : ReCaptchaEnterpriseProvider(_recaptchaWeb),
      providerAndroid: depuracao ? AndroidDebugProvider(debugToken: tokenUsado) : const AndroidPlayIntegrityProvider(),
      providerApple: depuracao ? AppleDebugProvider(debugToken: tokenUsado) : const AppleAppAttestProvider(),
    );
  } catch (e) {
    debugPrint('App Check não ativado: $e');
  }
}
