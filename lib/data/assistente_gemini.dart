import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'assistente.dart';
import 'instrucoes_assistente.dart';

export 'instrucoes_assistente.dart' show fontesOficiais, NivelSugerido;

/// Assistente com o Gemini pelo Firebase AI Logic (Gemini Developer API,
/// cota gratuita). Nenhuma chave de API fica no app: o Firebase faz a ponte,
/// protegido pelo App Check.
///
/// A instrução e os parâmetros ficam em `instrucoes_assistente.dart`, os mesmos
/// usados pelo roteiro de avaliação (`tool/avaliar_cenarios.dart`).
class AssistenteGemini extends Assistente {
  AssistenteGemini({GenerativeModel? modelo, this.limiteTurnos = 6}) : _modelo = modelo ?? _criarModelo();

  static const nomeModelo = modeloPadrao;

  final GenerativeModel _modelo;

  /// Quantas trocas anteriores vão junto, para entender perguntas de continuação.
  final int limiteTurnos;
  final List<Content> _historico = [];

  static GenerativeModel _criarModelo() {
    return FirebaseAI.googleAI().generativeModel(
      model: nomeModelo,
      systemInstruction: Content.system(instrucoesAssistente),
      generationConfig: GenerationConfig(
        temperature: temperaturaAssistente,
        maxOutputTokens: maxTokensAssistente,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'paragrafos': Schema.array(
              items: Schema.string(),
              minItems: 1,
              maxItems: maxParagrafosResposta,
              description: descricoesCampos['paragrafos'],
            ),
            'fonte': Schema.enumString(
              enumValues: fontesOficiais.keys.toList(),
              description: descricoesCampos['fonte'],
            ),
            'nivel': Schema.enumString(
              enumValues: NivelSugerido.values.map((n) => n.chave).toList(),
              description: descricoesCampos['nivel'],
            ),
            'justificativa': Schema.string(description: descricoesCampos['justificativa']),
            'oferecerOrientacao': Schema.boolean(description: descricoesCampos['oferecerOrientacao']),
            'pedirEsclarecimento': Schema.boolean(description: descricoesCampos['pedirEsclarecimento']),
          },
          propertyOrdering: ordemCampos,
        ),
      ),
    );
  }

  @override
  Future<RespostaEducativa> responder(String pergunta) async {
    final pronta = AssistenteLocal.respostaPronta(pergunta);
    if (pronta != null) {
      _lembrar(pergunta, pronta);
      return pronta;
    }

    final resposta = await _modelo
        .generateContent([..._historico, Content.text(pergunta)])
        .timeout(const Duration(seconds: 40));
    final convertida = converter(resposta.text);
    _lembrar(pergunta, convertida);
    return convertida;
  }

  @override
  void reiniciar() => _historico.clear();

  void _lembrar(String pergunta, RespostaEducativa resposta) {
    _historico
      ..add(Content.text(pergunta))
      ..add(Content.model([TextPart(resposta.paragrafos.join('\n\n'))]));
    final excesso = _historico.length - limiteTurnos * 2;
    if (excesso > 0) _historico.removeRange(0, excesso);
  }

  /// Converte o JSON do modelo. Fonte desconhecida vira o portal do Ministério;
  /// nível desconhecido ou "nao_se_aplica" não gera sugestão de serviço.
  @visibleForTesting
  static RespostaEducativa converter(String? texto) {
    if (texto == null || texto.trim().isEmpty) throw const FormatException('Resposta vazia do modelo');
    final json = jsonDecode(texto) as Map<String, dynamic>;
    // O esquema pede de 1 a 4 parágrafos; o corte vale mesmo se o modelo não obedecer.
    final paragrafos = (json['paragrafos'] as List)
        .map((p) => '$p'.trim())
        .where((p) => p.isNotEmpty)
        .take(maxParagrafosResposta)
        .toList();
    if (paragrafos.isEmpty) throw const FormatException('Resposta sem texto');
    final fonte = fontesOficiais[json['fonte']] ?? fontesOficiais['ministerio']!;
    if (pedeEsclarecimento(json)) {
      // Pergunta antes de classificar: sem card, mas com as opções manuais à mão.
      return RespostaEducativa(
        paragrafos: paragrafos,
        fonte: fonte.nome,
        url: fonte.url,
        oferecerOrientacao: true,
        pedeEsclarecimento: true,
      );
    }
    final nivel = NivelSugerido.daChave(json['nivel']);
    final sugere = nivel != null && nivel != NivelSugerido.naoSeAplica;
    final justificativa = '${json['justificativa'] ?? ''}'.trim();
    return RespostaEducativa(
      paragrafos: paragrafos,
      fonte: fonte.nome,
      url: fonte.url,
      nivel: nivel,
      justificativa: sugere && justificativa.isNotEmpty ? justificativa : null,
      // Com um nível sugerido, o próprio card do serviço oferece as outras opções.
      oferecerOrientacao: !sugere && json['oferecerOrientacao'] == true,
    );
  }
}
