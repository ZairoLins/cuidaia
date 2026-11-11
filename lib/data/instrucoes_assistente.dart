/// Instrução, parâmetros e formato de resposta do assistente.
///
/// Ficam num arquivo sem Flutter para que o app (`assistente_gemini.dart`) e o
/// roteiro de avaliação (`tool/avaliar_cenarios.dart`) usem exatamente o mesmo
/// texto e as mesmas regras: o que é avaliado é o que roda no app.
library;

import 'conteudos.dart';

/// Fontes que o assistente pode citar. A IA escolhe uma pela chave, e o link
/// vem daqui: assim ela nunca inventa um endereço.
const fontesOficiais = <String, ({String nome, String url})>{
  'ras': (
    nome: 'Portaria GM/MS nº 4.279/2010 — diretrizes da RAS',
    url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2010/prt4279_30_12_2010.html',
  ),
  'pnab': (
    nome: 'Política Nacional de Atenção Básica — Portaria nº 2.436/2017',
    url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/prt2436_22_09_2017.html',
  ),
  'decreto7508': (
    nome: 'Decreto nº 7.508/2011 — organização do SUS',
    url: 'https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/decreto/d7508.htm',
  ),
  'lei8080': (
    nome: 'Lei nº 8.080/1990 — Lei Orgânica da Saúde',
    url: 'https://www.planalto.gov.br/ccivil_03/leis/l8080.htm',
  ),
  'ministerio': (nome: 'Ministério da Saúde — gov.br/saude', url: 'https://www.gov.br/saude/pt-br'),
};

/// Classificação orientativa da demanda (não é diagnóstico). Segue as portas
/// de entrada e o ordenamento do acesso do Decreto nº 7.508/2011 (arts. 9º a 11).
enum NivelSugerido {
  primaria('primaria', 'Atenção Primária'),
  secundaria('secundaria', 'Atenção Secundária'),
  terciaria('terciaria', 'Atenção Terciária'),
  urgencia('urgencia', 'Urgência e emergência'),
  psicossocial('psicossocial', 'Atenção psicossocial'),
  naoSeAplica('nao_se_aplica', 'Não se aplica');

  const NivelSugerido(this.chave, this.rotulo);

  /// Valor usado no JSON do modelo e nas planilhas de avaliação.
  final String chave;
  final String rotulo;

  static NivelSugerido? daChave(Object? chave) {
    for (final n in values) {
      if (n.chave == chave) return n;
    }
    return null;
  }
}

/// Modelo usado no app e na avaliação. Troque sem mexer no código:
/// `--dart-define=GEMINI_MODELO=...`. O gemini-3.8-flash fica sem responder na
/// cota gratuita (testado em 07/11/2026); o 3.5-flash responde em poucos segundos.
const modeloPadrao = String.fromEnvironment('GEMINI_MODELO', defaultValue: 'gemini-3.5-flash');
const temperaturaAssistente = 0.3;

/// O raciocínio interno do modelo conta dentro de `maxOutputTokens`. Com 1024 e
/// raciocínio no padrão, o JSON saía cortado ("Unterminated string"). Raciocínio
/// baixo + folga de tokens resolve; a resposta em si continua curta pela instrução.
const maxTokensAssistente = 4096;

/// Máximo de parágrafos de uma resposta, no esquema e na conversão do JSON.
const maxParagrafosResposta = 4;
const nivelRaciocinio = 'LOW';

final instrucoesAssistente =
    '''
Você é o assistente do CuidaIA, um app educativo sobre o SUS (Sistema Único de Saúde do Brasil).

Objetivo: explicar, em português do Brasil e em linguagem simples, como funcionam o SUS, a Rede de Atenção à Saúde, os níveis de atenção e os serviços (UBS, UPA, SAMU, CAPS, hospitais), e orientar em qual nível de atenção a pessoa deve buscar atendimento para a situação que ela descreveu.

Regras:
- Escreva para quem tem pouca familiaridade com o tema: frases curtas, sem jargão; se usar uma sigla, explique.
- Use de 1 a 4 parágrafos curtos. Sem markdown, listas ou emojis.
- Baseie-se apenas em normas e materiais oficiais do Ministério da Saúde e na legislação do SUS. Se não tiver certeza, diga isso e indique o portal do Ministério da Saúde.
- Nunca faça diagnóstico, nunca diga qual doença a pessoa pode ter e nunca indique tratamentos, medicamentos ou doses. Você orienta sobre serviços, não sobre a doença.
- Se houver qualquer sinal de risco à vida, diga para ligar 192 (SAMU) imediatamente.
- Se a pessoa falar de sofrimento emocional, acolha com empatia e cite o CVV (ligue 188, gratuito, 24 horas) e os CAPS.
- Se a pergunta não tiver relação com saúde pública ou com o SUS, diga gentilmente que você só ajuda com esses temas.
- Não peça nem repita dados pessoais (CPF, endereço, Cartão SUS).

Classificação orientativa (campo "nivel"):
- Quando a pessoa descrever uma necessidade de saúde (sintoma, acompanhamento, exame, cirurgia, tratamento), indique o tipo de serviço que corresponde à situação:
  - primaria: cuidado contínuo, prevenção, vacinas, pré-natal, renovação de receitas, acompanhamento de doenças crônicas e problemas leves que podem esperar alguns dias. Porta de entrada preferencial: a UBS.
  - secundaria: consultas com especialistas e exames especializados, em ambulatórios e policlínicas.
  - terciaria: alta complexidade, como cirurgias complexas, tratamento de câncer, transplantes e internações especializadas em hospitais de referência.
  - urgencia: situações que precisam de atendimento no mesmo dia ou imediato (UPA, pronto-socorro ou SAMU).
  - psicossocial: sofrimento emocional ou uso problemático de álcool e outras drogas (UBS, CAPS; CVV 188).
  - nao_se_aplica: perguntas sobre o SUS que não descrevem uma necessidade de saúde, ou pedidos de orientação sem descrição da situação.
- No SUS, a atenção secundária e a terciária são acessadas por encaminhamento, a partir de uma porta de entrada (Decreto nº 7.508/2011). Quando classificar como secundaria ou terciaria, explique que o caminho começa pela UBS (ou pela equipe que já acompanha a pessoa), e não diga para ir direto ao especialista ou ao hospital, exceto em urgência.
- Na dúvida entre dois níveis, escolha o que exige atendimento mais rápido.
- Pergunta de esclarecimento: se o relato for curto demais para escolher o nível (por exemplo, falta saber há quanto tempo começou, a intensidade, a idade ou se há outros sinais) e não houver nenhum sinal de risco à vida, não classifique ainda. Marque pedirEsclarecimento como true, use nivel nao_se_aplica e, nos parágrafos, faça UMA pergunta curta e objetiva sobre o que falta. Inclua também uma frase dizendo que, se houver piora ou sinal de gravidade, a pessoa deve ligar 192 ou procurar uma UPA.
- Pergunte no máximo uma vez seguida: se a sua mensagem anterior já foi uma pergunta de esclarecimento, classifique com o que a pessoa respondeu. Havendo qualquer sinal de risco, nunca pergunte: oriente a urgência.
- Em "justificativa", escreva uma frase curta que ligue a situação descrita à função do nível escolhido, sem diagnóstico. Se nivel for nao_se_aplica, deixe "justificativa" vazia.
- Marque oferecerOrientacao como true apenas quando a pessoa pedir ajuda para saber onde ser atendida sem descrever a situação.

Escolha em "fonte" a referência que melhor embasa a resposta:
${fontesOficiais.entries.map((e) => '- ${e.key}: ${e.value.nome}').join('\n')}

Contexto do app (já revisado), use como base:
${niveisAtencao.map((n) => '- ${n.titulo}: ${n.descricao}').join('\n')}
- ${artigos['vigilancia']!.categoria}: ${artigos['vigilancia']!.lead} Inclui a vigilância epidemiológica, a sanitária e a saúde do trabalhador (Lei nº 8.080/1990, art. 6º) e faz parte das ações da Atenção Primária (PNAB).
''';

/// Formato da resposta no padrão da API REST do Gemini (usado pelo roteiro de
/// avaliação). O app monta o mesmo formato com `Schema` do firebase_ai.
final esquemaRespostaRest = <String, Object>{
  'type': 'OBJECT',
  'properties': {
    'paragrafos': {
      'type': 'ARRAY',
      'items': {'type': 'STRING'},
      'minItems': 1,
      'maxItems': maxParagrafosResposta,
      'description': descricoesCampos['paragrafos']!,
    },
    'fonte': {
      'type': 'STRING',
      'format': 'enum',
      'enum': fontesOficiais.keys.toList(),
      'description': descricoesCampos['fonte']!,
    },
    'nivel': {
      'type': 'STRING',
      'format': 'enum',
      'enum': NivelSugerido.values.map((n) => n.chave).toList(),
      'description': descricoesCampos['nivel']!,
    },
    'justificativa': {'type': 'STRING', 'description': descricoesCampos['justificativa']!},
    'oferecerOrientacao': {'type': 'BOOLEAN', 'description': descricoesCampos['oferecerOrientacao']!},
    'pedirEsclarecimento': {'type': 'BOOLEAN', 'description': descricoesCampos['pedirEsclarecimento']!},
  },
  'required': ordemCampos,
  'propertyOrdering': ordemCampos,
};

const ordemCampos = ['paragrafos', 'fonte', 'nivel', 'justificativa', 'oferecerOrientacao', 'pedirEsclarecimento'];

/// Rótulo usado no gabarito e nas planilhas quando o assistente pergunta antes
/// de classificar. Não é um nível de atenção: é um tipo de resposta.
const rotuloEsclarecer = 'esclarecer';

/// Se a resposta do modelo é uma pergunta de esclarecimento. Uma indicação de
/// urgência sempre prevalece, mesmo que o modelo também peça mais informações.
bool pedeEsclarecimento(Map<String, dynamic> json) =>
    json['pedirEsclarecimento'] == true && NivelSugerido.daChave(json['nivel']) != NivelSugerido.urgencia;

/// Rótulo da resposta para a avaliação: a chave do nível, [rotuloEsclarecer]
/// ou 'invalido'. App e roteiro usam a mesma regra.
String rotuloDaResposta(Map<String, dynamic> json) {
  if (pedeEsclarecimento(json)) return rotuloEsclarecer;
  return NivelSugerido.daChave(json['nivel'])?.chave ?? 'invalido';
}

const descricoesCampos = {
  'paragrafos': 'Resposta em 1 a 4 parágrafos curtos, em linguagem simples.',
  'fonte': 'Chave da fonte oficial que embasa a resposta.',
  'nivel': 'Nível de atenção indicado para a situação descrita (orientação, não diagnóstico).',
  'justificativa': 'Uma frase ligando a situação à função do nível escolhido, sem diagnóstico. Vazia se nao_se_aplica.',
  'oferecerOrientacao': 'true só quando a pessoa pede onde ser atendida sem descrever a situação.',
  'pedirEsclarecimento':
      'true quando falta informação para escolher o nível e não há sinal de risco; a resposta é uma pergunta curta.',
};
