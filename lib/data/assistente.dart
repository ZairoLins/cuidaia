import 'dart:ui' show Color;

import '../theme/cuida_tema.dart';

/// Resposta educativa do assistente, sempre com a fonte oficial.
class RespostaEducativa {
  const RespostaEducativa({
    required this.paragrafos,
    required this.fonte,
    required this.url,
    this.oferecerOrientacao = false,
  });

  final List<String> paragrafos;
  final String fonte;
  final String url;
  final bool oferecerOrientacao;
}

class AcaoLigar {
  const AcaoLigar(this.texto, this.numero);
  final String texto;
  final String numero;
}

/// Serviço indicado pela orientação de atendimento (não é diagnóstico).
class Servico {
  const Servico({
    required this.chave,
    required this.nivel,
    required this.titulo,
    required this.texto,
    required this.lista,
    this.acao,
    this.extra,
    this.urgente = false,
  });

  final String chave;
  final String nivel;
  final String titulo;
  final String texto;
  final List<String> lista;
  final AcaoLigar? acao;
  final String? extra;
  final bool urgente;
}

class OpcaoAtendimento {
  const OpcaoAtendimento(this.chave, this.titulo, this.descricao, this.cor);
  final String chave;
  final String titulo;
  final String descricao;
  final Color cor;
}

const servicos = <String, Servico>{
  'samu': Servico(
    chave: 'samu',
    nivel: 'Emergência',
    titulo: 'Ligue 192 (SAMU) agora',
    texto: 'Situações com risco à vida precisam de atendimento imediato. O SAMU funciona 24 horas, e a ligação é gratuita.',
    lista: ['Diga o endereço completo e o que está acontecendo', 'Siga as orientações da equipe até a ajuda chegar'],
    acao: AcaoLigar('Ligar 192', '192'),
    extra: 'Se for mais rápido, vá ao pronto-socorro mais próximo.',
    urgente: true,
  ),
  'upa': Servico(
    chave: 'upa',
    nivel: 'Urgência · atendimento no mesmo dia',
    titulo: 'Procure uma UPA 24h ou pronto-socorro',
    texto: 'Para problemas que precisam de atendimento hoje, mas sem risco imediato à vida.',
    lista: [
      'Leve documento com foto e Cartão SUS ou CPF',
      'Lá, a equipe faz a classificação de risco: quem está em situação mais grave é atendido primeiro',
    ],
    extra: 'Se a situação piorar, ligue 192.',
  ),
  'ubs': Servico(
    chave: 'ubs',
    nivel: 'Atenção Primária',
    titulo: 'Procure a sua UBS',
    texto: 'Para consultas, acompanhamento, vacinas, renovação de receitas e exames de rotina.',
    lista: [
      'A UBS de referência costuma ser a mais próxima da sua casa — a Secretaria Municipal de Saúde informa qual é a sua',
      'Leve documento com foto, Cartão SUS ou CPF e comprovante de endereço',
    ],
    extra: 'Se precisar de um especialista, a própria equipe da UBS faz o encaminhamento.',
  ),
  'mental': Servico(
    chave: 'mental',
    nivel: 'Saúde mental',
    titulo: 'Você não precisa passar por isso sozinho(a)',
    texto: 'A UBS e os Centros de Atenção Psicossocial (CAPS) acolhem pessoas em sofrimento emocional.',
    lista: [
      'CVV — Centro de Valorização da Vida: ligue 188, gratuito e 24 horas',
      'Se houver risco imediato à vida, ligue 192 (SAMU)',
    ],
    acao: AcaoLigar('Ligar 188 (CVV)', '188'),
    extra: 'Conversar com alguém de confiança também ajuda.',
  ),
};

const opcoesAtendimento = [
  OpcaoAtendimento('samu', 'Risco à vida agora',
      'Dor forte no peito, falta de ar intensa, desmaio, sinais de AVC, sangramento grave', CuidaCores.erro),
  OpcaoAtendimento('upa', 'Preciso de atendimento hoje',
      'Febre alta, corte, queda, dor forte que não passa — sem risco imediato à vida', CuidaCores.laranja),
  OpcaoAtendimento('ubs', 'Pode esperar alguns dias', 'Consulta, acompanhamento, vacina, receita, exames de rotina',
      CuidaCores.verde700),
  OpcaoAtendimento('mental', 'Sofrimento emocional', 'Angústia, tristeza persistente, crise de ansiedade', CuidaCores.azul),
];

const perguntasSugeridas = [
  'O que é a Rede de Atenção à Saúde?',
  'Qual é a função da Atenção Primária?',
  'Qual a diferença entre os níveis de atenção?',
];

enum Classificacao { samu, mental, orientar }

/// Triagem por palavras-chave: situações de risco nunca vão para a IA.
Classificacao? classificar(String texto) {
  final x = texto.toLowerCase();
  bool tem(List<String> termos) => termos.any(x.contains);
  if (tem(['suicid', 'me matar', 'tirar minha vida', 'tirar a minha vida', 'me machucar', 'acabar com tudo',
      'não quero mais viver', 'nao quero mais viver'])) {
    return Classificacao.mental;
  }
  if (tem(['dor no peito', 'falta de ar', 'não consigo respirar', 'nao consigo respirar', 'desmai', 'avc', 'derrame',
      'convuls', 'sangramento', 'sangrando muito', 'infarto', 'inconsciente', 'envenen', 'engasg'])) {
    return Classificacao.samu;
  }
  if (tem(['onde procurar', 'onde ir', 'onde devo', 'qual serviço', 'qual servico', 'onde ser atendid',
      'onde buscar atendimento'])) {
    return Classificacao.orientar;
  }
  return null;
}

/// Ponto de integração com o modelo de IA. Em produção: `AssistenteGemini`
/// (lib/data/assistente_gemini.dart); nos testes: [AssistenteLocal].
abstract class Assistente {
  const Assistente();

  Future<RespostaEducativa> responder(String pergunta);

  /// Esquece o contexto da conversa (ao apagar o histórico ou sair).
  void reiniciar() {}
}

/// Respostas fixas, baseadas em documentos oficiais.
class AssistenteLocal extends Assistente {
  const AssistenteLocal({this.atraso = const Duration(milliseconds: 1800)});

  /// Resposta revisada para as perguntas sugeridas, sem gastar a cota da IA.
  static RespostaEducativa? respostaPronta(String pergunta) => _respostas[pergunta.trim()];

  final Duration atraso;

  static const _respostas = <String, RespostaEducativa>{
    'O que é a Rede de Atenção à Saúde?': RespostaEducativa(
      paragrafos: [
        'A Rede de Atenção à Saúde (RAS) é a forma como o SUS organiza seus serviços para que funcionem juntos, e não como pontos isolados.',
        'Ela reúne unidades básicas, serviços especializados, hospitais e a rede de urgência, ligados por regulação, transporte e informação.',
        'A Atenção Primária coordena esse cuidado: acompanha você ao longo do tempo e organiza o acesso aos outros serviços quando necessário.',
      ],
      fonte: 'Portaria GM/MS nº 4.279/2010 — diretrizes da RAS',
      url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2010/prt4279_30_12_2010.html',
    ),
    'Qual é a função da Atenção Primária?': RespostaEducativa(
      paragrafos: [
        'É o primeiro contato preferencial com o SUS, nas Unidades Básicas de Saúde (UBS) e com as equipes de Saúde da Família.',
        'Ela cuida da promoção da saúde, da prevenção, de vacinas, do pré-natal e do acompanhamento de condições crônicas — e resolve grande parte das necessidades.',
        'Quando é preciso, encaminha para outros serviços e continua acompanhando você depois.',
      ],
      fonte: 'Política Nacional de Atenção Básica — Portaria nº 2.436/2017',
      url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/prt2436_22_09_2017.html',
    ),
    'Qual a diferença entre os níveis de atenção?': RespostaEducativa(
      paragrafos: [
        'Primária: cuidado contínuo e perto de casa, nas UBS.',
        'Secundária: consultas com especialistas e exames, em ambulatórios e policlínicas.',
        'Terciária: alta complexidade, como internações especializadas e cirurgias complexas, em hospitais de referência.',
        'Esses níveis não são degraus fixos: eles se comunicam, e o caminho depende de cada situação.',
      ],
      fonte: 'Portaria GM/MS nº 4.279/2010 — diretrizes da RAS',
      url: 'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2010/prt4279_30_12_2010.html',
    ),
  };

  static const _padrao = RespostaEducativa(
    paragrafos: [
      'Sem conexão com o assistente de IA, só consigo responder às perguntas sugeridas. Para outras dúvidas, consulte o portal do Ministério da Saúde.',
      'Eu não avalio sintomas, mas posso ajudar você a escolher o serviço mais adequado.',
    ],
    fonte: 'Ministério da Saúde — gov.br/saude',
    url: 'https://www.gov.br/saude/pt-br',
    oferecerOrientacao: true,
  );

  @override
  Future<RespostaEducativa> responder(String pergunta) async {
    await Future<void>.delayed(atraso);
    return _respostas[pergunta.trim()] ?? _padrao;
  }
}
