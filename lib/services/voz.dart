import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Leitura em voz alta (pt-BR) das respostas do assistente.
class Voz {
  Voz._();

  static final instancia = Voz._();

  late final FlutterTts _tts = FlutterTts();
  bool _pronto = false;

  /// Id da mensagem sendo lida agora, ou null.
  final ValueNotifier<String?> falando = ValueNotifier(null);

  Future<void> _preparar() async {
    if (_pronto) return;
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.5);
    _tts.setCompletionHandler(() => falando.value = null);
    _tts.setCancelHandler(() => falando.value = null);
    _tts.setErrorHandler((_) => falando.value = null);
    _pronto = true;
  }

  Future<void> falar(String id, String texto) async {
    try {
      await _preparar();
      await _tts.stop();
      falando.value = id;
      await _tts.speak(texto);
    } catch (_) {
      falando.value = null;
    }
  }

  Future<void> alternar(String id, String texto) {
    if (falando.value == id) return parar();
    return falar(id, texto);
  }

  Future<void> parar() async {
    falando.value = null;
    if (!_pronto) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
