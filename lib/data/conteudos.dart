/// Conteúdo educativo sobre a Rede de Atenção à Saúde (RAS).
library;

class Referencia {
  const Referencia(this.titulo, this.descricao, this.url);
  final String titulo;
  final String descricao;
  final String url;
}

class SecaoArtigo {
  const SecaoArtigo(this.titulo, this.paragrafos, [this.itens = const []]);
  final String titulo;
  final List<String> paragrafos;
  final List<String> itens;
}

class Artigo {
  const Artigo({
    required this.topico,
    required this.categoria,
    required this.titulo,
    required this.tempo,
    required this.lead,
    required this.diagramaRotulo,
    required this.secoes,
    required this.destaqueTitulo,
    required this.destaque,
    required this.refs,
    required this.nivelAtivo,
  });

  final String topico;
  final String categoria;
  final String titulo;
  final String tempo;
  final String lead;
  final String diagramaRotulo;
  final List<SecaoArtigo> secoes;
  final String destaqueTitulo;
  final String destaque;
  final List<Referencia> refs;
  final int nivelAtivo;
}

class NivelAtencao {
  const NivelAtencao({
    required this.numero,
    required this.rotulo,
    required this.titulo,
    required this.resumo,
    required this.descricao,
    required this.exemplos,
    required this.topico,
  });

  final String numero;
  final String rotulo;
  final String titulo;
  final String resumo;
  final String descricao;
  final String exemplos;
  final String topico;
}

class ItemTexto {
  const ItemTexto(this.titulo, this.descricao);
  final String titulo;
  final String descricao;
}

const refRas = Referencia(
  'Portaria GM/MS nº 4.279/2010',
  'Diretrizes para a organização da Rede de Atenção à Saúde',
  'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2010/prt4279_30_12_2010.html',
);
const refPnab = Referencia(
  'Portaria nº 2.436/2017 — PNAB',
  'Política Nacional de Atenção Básica',
  'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/prt2436_22_09_2017.html',
);
const refDecreto = Referencia(
  'Decreto nº 7.508/2011',
  'Organização do SUS, regiões de saúde e portas de entrada',
  'https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/decreto/d7508.htm',
);
const refLei8080 = Referencia(
  'Lei nº 8.080/1990',
  'Lei Orgânica da Saúde',
  'https://www.planalto.gov.br/ccivil_03/leis/l8080.htm',
);
const refLgpd = Referencia(
  'Lei nº 13.709/2018 — LGPD',
  'Texto completo · Planalto',
  'https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm',
);

const niveisAtencao = [
  NivelAtencao(
    numero: '01',
    rotulo: 'Porta de entrada',
    titulo: 'Atenção Primária',
    resumo: 'UBS e Saúde da Família, perto de casa',
    descricao:
        'Primeiro contato preferencial com o SUS e coordenadora do cuidado. Promove saúde, previne doenças, acompanha você ao longo do tempo e encaminha quando necessário.',
    exemplos: 'UBS · Saúde da Família · Vacinação · Pré-natal',
    topico: 'primaria',
  ),
  NivelAtencao(
    numero: '02',
    rotulo: 'Atendimento especializado',
    titulo: 'Atenção Secundária',
    resumo: 'Especialistas e exames em ambulatórios',
    descricao:
        'Consultas com especialistas e serviços ambulatoriais especializados, com apoio de exames diagnósticos, em policlínicas e centros de especialidades.',
    exemplos: 'Cardiologia · Ultrassonografia · Endoscopia · Centros odontológicos',
    topico: 'secundaria',
  ),
  NivelAtencao(
    numero: '03',
    rotulo: 'Alta complexidade',
    titulo: 'Atenção Terciária',
    resumo: 'Alta complexidade em hospitais de referência',
    descricao:
        'Serviços de maior complexidade e densidade tecnológica, geralmente em hospitais de referência que atendem toda uma região.',
    exemplos: 'UTI · Cirurgia cardíaca · Transplantes · Oncologia',
    topico: 'terciaria',
  ),
];

const conexoesRede = [
  ItemTexto('Encaminhamento',
      'Quando você precisa de um especialista ou exame, a equipe que acompanha você faz o pedido com as informações do seu caso.'),
  ItemTexto('Regulação',
      'Centrais de regulação organizam vagas de consultas, exames e internações conforme a necessidade e a prioridade de cada caso.'),
  ItemTexto('Retorno (contrarreferência)',
      'Depois do atendimento especializado, as informações voltam para a UBS, que continua acompanhando você.'),
  ItemTexto('Urgência e emergência',
      'UPA 24h, pronto-socorro e SAMU 192 atendem situações urgentes a qualquer hora e acionam outros serviços quando preciso.'),
];

const percursoExemplo = [
  ItemTexto('Consulta na UBS', 'Em uma consulta de rotina, a equipe identifica pressão alta e começa o acompanhamento.'),
  ItemTexto('Encaminhamento e regulação',
      'Para avaliar o coração, ele é encaminhado à cardiologia. A regulação agenda a consulta.'),
  ItemTexto('Atenção especializada', 'No ambulatório de especialidades, faz a consulta e os exames solicitados.'),
  ItemTexto('De volta à UBS', 'O relatório retorna à equipe, que segue cuidando dele perto de casa.'),
];

const referenciasAprenda = [
  Referencia('Portaria GM/MS nº 4.279/2010', 'Diretrizes para a organização da RAS · Ministério da Saúde',
      'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2010/prt4279_30_12_2010.html'),
  Referencia('Portaria nº 2.436/2017 — PNAB', 'Política Nacional de Atenção Básica · Ministério da Saúde',
      'https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/prt2436_22_09_2017.html'),
  Referencia('Decreto nº 7.508/2011', 'Organização do SUS e portas de entrada · Planalto',
      'https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/decreto/d7508.htm'),
  Referencia('Lei nº 8.080/1990', 'Lei Orgânica da Saúde · Planalto', 'https://www.planalto.gov.br/ccivil_03/leis/l8080.htm'),
];

const assuntosExplorar = [
  'Vacinação',
  'Saúde mental',
  'Saúde bucal',
  'Medicamentos',
  'Gestação',
  'Direitos do usuário',
];

const artigos = <String, Artigo>{
  'primaria': Artigo(
    topico: 'primaria',
    categoria: 'Atenção Primária',
    titulo: 'Atenção Primária: a porta de entrada do SUS',
    tempo: 'Leitura de 5 min',
    lead:
        'É o cuidado mais próximo de você. Nas Unidades Básicas de Saúde, as equipes acompanham sua saúde ao longo do tempo e ajudam a organizar o acesso a outros serviços.',
    diagramaRotulo: 'Atenção Primária destacada, ligada nos dois sentidos à Secundária e à Terciária.',
    secoes: [
      SecaoArtigo('O que é', [
        'A Atenção Primária à Saúde (APS) é o primeiro contato preferencial das pessoas com o SUS. Ela funciona perto de onde as pessoas moram, trabalham e convivem.',
        'Por estar próxima da comunidade, a equipe conhece o território e pode acompanhar as famílias por muitos anos.',
      ]),
      SecaoArtigo('O que você encontra na UBS', [
        'Os serviços variam de um município para outro, mas é comum encontrar:',
      ], [
        'Consultas com médicos, enfermeiros e dentistas',
        'Vacinação',
        'Pré-natal e acompanhamento do crescimento das crianças',
        'Acompanhamento de condições crônicas, como hipertensão e diabetes',
        'Curativos, testes rápidos e orientações sobre medicamentos',
      ]),
      SecaoArtigo('Quem faz parte da equipe', [
        'As equipes de Saúde da Família costumam reunir médico, enfermeiro, técnico ou auxiliar de enfermagem e agentes comunitários de saúde. Muitas também contam com equipe de saúde bucal.',
      ]),
      SecaoArtigo('Coordenação do cuidado', [
        'Quando você precisa de um especialista ou de um exame específico, a equipe faz o encaminhamento e acompanha o resultado. Depois, as informações voltam para a UBS, que continua cuidando de você.',
      ]),
    ],
    destaqueTitulo: 'Importante',
    destaque:
        'Em urgências ou emergências, você não precisa passar pela UBS antes: procure uma UPA 24h, um pronto-socorro ou ligue 192 (SAMU).',
    refs: [refPnab, refRas],
    nivelAtivo: 0,
  ),
  'secundaria': Artigo(
    topico: 'secundaria',
    categoria: 'Atenção Secundária',
    titulo: 'Atenção Secundária: o cuidado especializado',
    tempo: 'Leitura de 4 min',
    lead:
        'Reúne consultas com especialistas e exames que exigem equipamentos ou profissionais específicos, geralmente em ambulatórios e policlínicas.',
    diagramaRotulo: 'Atenção Secundária destacada, ligada nos dois sentidos à Primária e à Terciária.',
    secoes: [
      SecaoArtigo('O que é', [
        'A atenção especializada ambulatorial apoia a Atenção Primária quando é preciso um olhar mais específico sobre um problema de saúde.',
      ]),
      SecaoArtigo('Exemplos de serviços', [
        'Dependendo da região, a rede pode oferecer:',
      ], [
        'Consultas com cardiologistas, ortopedistas, dermatologistas e outros especialistas',
        'Exames como ultrassonografia e endoscopia',
        'Centros de Especialidades Odontológicas (CEO)',
        'Centros de Atenção Psicossocial (CAPS), na área de saúde mental',
      ]),
      SecaoArtigo('Como se chega até ela', [
        'Na maioria dos casos, o acesso começa com um encaminhamento da UBS. A central de regulação organiza as vagas considerando a necessidade e a prioridade de cada pessoa.',
        'Alguns serviços, como os CAPS, também podem receber pessoas diretamente. As regras variam conforme o município.',
      ]),
      SecaoArtigo('Depois do atendimento', [
        'O serviço especializado envia informações à equipe da UBS (contrarreferência), para que o acompanhamento continue perto de casa.',
      ]),
    ],
    destaqueTitulo: 'Você sabia?',
    destaque:
        'A ordem de atendimento na regulação considera a prioridade clínica de cada caso, e não apenas a ordem de chegada.',
    refs: [refRas, refDecreto],
    nivelAtivo: 1,
  ),
  'terciaria': Artigo(
    topico: 'terciaria',
    categoria: 'Atenção Terciária',
    titulo: 'Atenção Terciária: a alta complexidade',
    tempo: 'Leitura de 4 min',
    lead:
        'São serviços que exigem tecnologia avançada e equipes altamente especializadas, oferecidos principalmente em hospitais de referência.',
    diagramaRotulo: 'Atenção Terciária destacada, ligada nos dois sentidos à Primária e à Secundária.',
    secoes: [
      SecaoArtigo('O que é', [
        'A atenção de alta complexidade reúne procedimentos de maior densidade tecnológica. Esses serviços costumam ser organizados por região, atendendo a população de vários municípios.',
      ]),
      SecaoArtigo('Exemplos', [
        'Fazem parte deste nível, por exemplo:',
      ], [
        'Internações em UTI e em enfermarias especializadas',
        'Cirurgias cardíacas e neurocirurgias',
        'Transplantes de órgãos',
        'Tratamento do câncer, como quimioterapia e radioterapia',
        'Hemodiálise',
      ]),
      SecaoArtigo('Como se chega até ela', [
        'O acesso pode acontecer por encaminhamento e regulação, a partir de outros serviços da rede, ou pela urgência e emergência, quando há risco à vida.',
      ]),
      SecaoArtigo('Continuidade do cuidado', [
        'Após a alta hospitalar, a equipe da Atenção Primária retoma o acompanhamento, com apoio do serviço especializado quando necessário.',
      ]),
    ],
    destaqueTitulo: 'Importante',
    destaque:
        'Alta complexidade não quer dizer atendimento mais importante: cada nível tem um papel diferente, e todos trabalham juntos.',
    refs: [refRas, refLei8080],
    nivelAtivo: 2,
  ),
};
