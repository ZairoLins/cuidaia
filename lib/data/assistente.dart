import 'dart:ui' show Color;

import '../theme/cuida_tema.dart';
import 'instrucoes_assistente.dart';

export 'instrucoes_assistente.dart' show NivelSugerido;
export 'triagem.dart';

/// Resposta educativa do assistente, sempre com a fonte oficial.
class RespostaEducativa {
  const RespostaEducativa({
    required this.paragrafos,
    required this.fonte,
    required this.url,
    this.oferecerOrientacao = false,
    this.nivel,
    this.justificativa,
    this.pedeEsclarecimento = false,
  });

  final List<String> paragrafos;
  final String fonte;
  final String url;
  final bool oferecerOrientacao;

  /// O assistente pediu mais informações antes de sugerir um nível.
  final bool pedeEsclarecimento;

  /// Nível de atenção sugerido pela IA (classificação orientativa, não diagnóstico).
  final NivelSugerido? nivel;

  /// Por que a situação descrita combina com o nível sugerido.
  final String? justificativa;

  /// Serviço a mostrar como sugestão, ou null quando não há sugestão.
  Servico? get servicoSugerido => servicoDoNivel(nivel);
}

/// Card de serviço que corresponde a cada nível sugerido pela IA.
Servico? servicoDoNivel(NivelSugerido? nivel) => switch (nivel) {
  NivelSugerido.primaria => servicos['ubs'],
  NivelSugerido.secundaria => servicos['secundaria'],
  NivelSugerido.terciaria => servicos['terciaria'],
  NivelSugerido.urgencia => servicos['upa'],
  NivelSugerido.psicossocial => servicos['mental'],
  NivelSugerido.naoSeAplica || null => null,
};

/// Artigo da aba Aprenda sobre o nível, quando existe.
String? artigoDoNivel(NivelSugerido? nivel) => switch (nivel) {
  NivelSugerido.primaria => 'primaria',
  NivelSugerido.secundaria => 'secundaria',
  NivelSugerido.terciaria => 'terciaria',
  _ => null,
};

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
    this.mapa,
  });

  final String chave;
  final String nivel;
  final String titulo;
  final String texto;
  final List<String> lista;
  final AcaoLigar? acao;
  final String? extra;
  final bool urgente;

  /// Busca no app de mapas do celular ("Ver UBS perto de mim"). Fica de fora
  /// no SAMU: com risco à vida, a orientação é ligar 192, não se deslocar.
  final BuscaMapa? mapa;
}

/// Tipo de unidade buscado no mapa: o rótulo do botão e o termo da busca.
class BuscaMapa {
  const BuscaMapa(this.rotulo, this.termo);
  final String rotulo;
  final String termo;
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
    mapa: BuscaMapa('Ver UPAs perto de mim', 'UPA 24h'),
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
    mapa: BuscaMapa('Ver UBS perto de mim', 'Unidade Básica de Saúde'),
  ),
  'secundaria': Servico(
    chave: 'secundaria',
    nivel: 'Atenção Secundária · por encaminhamento',
    titulo: 'Comece pela sua UBS',
    texto: 'Consultas com especialistas e exames especializados são feitos em ambulatórios e policlínicas. No SUS, o acesso a eles acontece por encaminhamento: a equipe da UBS avalia sua situação e, se for preciso, encaminha você.',
    lista: [
      'Leve documento com foto, Cartão SUS ou CPF e os exames e receitas que já tiver',
      'O pedido entra na regulação, que organiza o atendimento de acordo com a prioridade de cada caso',
      'Depois da consulta com o especialista, a UBS continua acompanhando você',
    ],
    extra: 'Se a situação piorar de repente, procure uma UPA ou ligue 192.',
    mapa: BuscaMapa('Ver UBS perto de mim', 'Unidade Básica de Saúde'),
  ),
  'terciaria': Servico(
    chave: 'terciaria',
    nivel: 'Atenção Terciária · por encaminhamento',
    titulo: 'O acesso é por encaminhamento',
    texto: 'Cirurgias complexas, tratamento de câncer, transplantes e internações especializadas são feitos em hospitais de referência. Fora das urgências, o acesso acontece por encaminhamento da UBS ou do especialista que já acompanha você.',
    lista: [
      'Se você ainda não tem acompanhamento, comece pela UBS',
      'Se já tem, converse com a equipe que acompanha você sobre o encaminhamento',
      'Guarde laudos, exames e receitas: eles ajudam na regulação do seu caso',
    ],
    extra: 'Em uma emergência, ligue 192 ou vá ao pronto-socorro.',
    mapa: BuscaMapa('Ver UBS perto de mim', 'Unidade Básica de Saúde'),
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
    mapa: BuscaMapa('Ver CAPS perto de mim', 'Centro de Atenção Psicossocial CAPS'),
  ),
};

const opcoesAtendimento = [
  OpcaoAtendimento(
    'samu',
    'Risco à vida agora',
    'Dor forte no peito, falta de ar intensa, desmaio, sinais de AVC, sangramento grave',
    CuidaCores.erro,
  ),
  OpcaoAtendimento(
    'upa',
    'Preciso de atendimento hoje',
    'Febre alta, corte, queda, dor forte que não passa — sem risco imediato à vida',
    CuidaCores.alerta,
  ),
  OpcaoAtendimento(
    'ubs',
    'Pode esperar alguns dias',
    'Consulta, acompanhamento, vacina, receita, exames de rotina',
    CuidaCores.acao,
  ),
  OpcaoAtendimento(
    'mental',
    'Sofrimento emocional',
    'Angústia, tristeza persistente, crise de ansiedade',
    CuidaCores.tinta,
  ),
];

const perguntasSugeridas = [
  'O que é a Rede de Atenção à Saúde?',
  'Qual é a função da Atenção Primária?',
  'Qual a diferença entre os níveis de atenção?',
];

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
