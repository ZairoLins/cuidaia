import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'assistente.dart';
import 'conteudos.dart';

/// Fontes que o assistente pode citar. A IA escolhe uma pela chave, e o link
/// vem daqui: assim ela nunca inventa um endereço.
const fontesOficiais = <String, ({String nome, String url})>{
  'ras': (nome: 'Portaria GM/MS nº 4.279/2010 — diretrizes da RAS', url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2010/prt4279_30_12_2010.html'),
  'pnab': (nome: 'Política Nacional de Atenção Básica — Portaria nº 2.436/2017', url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/prt2436_22_09_2017.html'),
  'decreto7508': (nome: 'Decreto nº 7.508/2011 — organização do SUS', url: 'https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/decreto/d7508.htm'),
  'lei8080': (nome: 'Lei nº 8.080/1990 — Lei Orgânica da Saúde', url: 'https://www.planalto.gov.br/ccivil_03/leis/l8080.htm'),
  'ministerio': (nome: 'Ministério da Saúde — gov.br/saude', url: 'https://www.gov.br/saude/pt-br'),
};

/// Assistente com o Gemini pelo Firebase AI Logic (Gemini Developer API,
/// cota gratuita). Nenhuma chave de API fica no app: o Firebase faz a ponte,
/// protegido pelo App Check.
class AssistenteGemini extends Assistente {
  AssistenteGemini({GenerativeModel? modelo, this.limiteTurnos = 6}) : _modelo = modelo ?? _criarModelo();

  /// Troque sem recompilar o código: `--dart-define=GEMINI_MODELO=...`.
  static const nomeModelo = String.fromEnvironment('GEMINI_MODELO', defaultValue: 'gemini-3.8-flash');

  final GenerativeModel _modelo;

  /// Quantas trocas anteriores vão junto, para entender perguntas de continuação.
  final int limiteTurnos;
  final List<Content> _historico = [];

  static GenerativeModel _criarModelo() {
    return FirebaseAI.googleAI().generativeModel(
      model: nomeModelo,
      systemInstruction: Content.system(_instrucoes),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'paragrafos': Schema.array(
              items: Schema.string(),
              minItems: 1,
              maxItems: 4,
              description: 'Resposta em 1 a 4 parágrafos curtos, em linguagem simples.',
            ),
            'fonte': Schema.enumString(
              enumValues: fontesOficiais.keys.toList(),
              description: 'Chave da fonte oficial que embasa a resposta.',
            ),
            'oferecerOrientacao': Schema.boolean(
              description: 'true se a pessoa descreveu sintomas ou perguntou onde ser atendida.',
            ),
          },
          propertyOrdering: ['paragrafos', 'fonte', 'oferecerOrientacao'],
        ),
      ),
    );
  }

  static final _instrucoes = '''
Você é o assistente do CuidaIA, um app educativo sobre o SUS (Sistema Único de Saúde do Brasil).

Objetivo: explicar, em português do Brasil e em linguagem simples, como funcionam o SUS, a Rede de Atenção à Saúde, os níveis de atenção e os serviços (UBS, UPA, SAMU, CAPS, hospitais).

Regras:
- Escreva para quem tem pouca familiaridade com o tema: frases curtas, sem jargão; se usar uma sigla, explique.
- Use de 1 a 4 parágrafos curtos. Sem markdown, listas ou emojis.
- Baseie-se apenas em normas e materiais oficiais do Ministério da Saúde e na legislação do SUS. Se não tiver certeza, diga isso e indique o portal do Ministério da Saúde.
- Nunca faça diagnóstico, nunca avalie a gravidade de sintomas e nunca indique tratamentos, medicamentos ou doses.
- Se a pessoa descrever sintomas ou perguntar onde ser atendida, explique que você não avalia sintomas e marque oferecerOrientacao como true. Se houver qualquer sinal de risco à vida, diga para ligar 192 (SAMU) imediatamente.
- Se a pessoa falar de sofrimento emocional, acolha com empatia e cite o CVV (ligue 188, gratuito, 24 horas) e os CAPS.
- Se a pergunta não tiver relação com saúde pública ou com o SUS, diga gentilmente que você só ajuda com esses temas.
- Não peça nem repita dados pessoais (CPF, endereço, Cartão SUS).

Escolha em "fonte" a referência que melhor embasa a resposta:
${fontesOficiais.entries.map((e) => '- ${e.key}: ${e.value.nome}').join('\n')}

Contexto do app (já revisado), use como base:
${niveisAtencao.map((n) => '- ${n.titulo}: ${n.descricao}').join('\n')}
''';

  @override
  Future<RespostaEducativa> responder(String pergunta) async {
    final pronta = AssistenteLocal.respostaPronta(pergunta);
    if (pronta != null) {
      _lembrar(pergunta, pronta);
      return pronta;
    }

    final resposta = await _modelo
        .generateContent([..._historico, Content.text(pergunta)]).timeout(const Duration(seconds: 40));
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

  /// Converte o JSON do modelo. Fonte desconhecida vira o portal do Ministério.
  @visibleForTesting
  static RespostaEducativa converter(String? texto) {
    if (texto == null || texto.trim().isEmpty) throw const FormatException('Resposta vazia do modelo');
    final json = jsonDecode(texto) as Map<String, dynamic>;
    final paragrafos = (json['paragrafos'] as List).map((p) => '$p'.trim()).where((p) => p.isNotEmpty).toList();
    if (paragrafos.isEmpty) throw const FormatException('Resposta sem texto');
    final fonte = fontesOficiais[json['fonte']] ?? fontesOficiais['ministerio']!;
    return RespostaEducativa(
      paragrafos: paragrafos,
      fonte: fonte.nome,
      url: fonte.url,
      oferecerOrientacao: json['oferecerOrientacao'] == true,
    );
  }
}
