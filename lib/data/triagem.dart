/// Triagem local por palavras-chave. Roda antes da IA, no app e no roteiro de
/// avaliação (`tool/avaliar_cenarios.dart`), por isso não depende do Flutter.
library;

enum Classificacao { samu, mental, orientar }

/// Pedidos de orientação com mais palavras que isso trazem uma descrição da
/// situação e seguem para a IA, que sugere o nível de atenção.
const limitePalavrasPedidoOrientacao = 8;

/// Situações de risco nunca vão para a IA.
Classificacao? classificar(String texto) {
  final x = texto.toLowerCase();
  bool tem(List<String> termos) => termos.any(x.contains);
  if (tem([
    'suicid',
    'me matar',
    'tirar minha vida',
    'tirar a minha vida',
    'me machucar',
    'acabar com tudo',
    'não quero mais viver',
    'nao quero mais viver',
  ])) {
    return Classificacao.mental;
  }
  if (tem([
    'dor no peito',
    'falta de ar',
    'não consigo respirar',
    'nao consigo respirar',
    'desmai',
    'avc',
    'derrame',
    'convuls',
    'sangramento',
    'sangrando muito',
    'infarto',
    'inconsciente',
    'envenen',
    'engasg',
  ])) {
    return Classificacao.samu;
  }
  final palavras = x.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;
  if (palavras <= limitePalavrasPedidoOrientacao &&
      tem([
        'onde procurar',
        'onde ir',
        'onde devo',
        'qual serviço',
        'qual servico',
        'onde ser atendid',
        'onde buscar atendimento',
      ])) {
    return Classificacao.orientar;
  }
  return null;
}
