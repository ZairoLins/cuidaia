import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'home_shell.dart';

/// Destino escolhido ao sair de um artigo.
enum SaidaArtigo { inicio, chat }

/// Abre um artigo e trata o retorno ("Ir para o início" ou "Pergunte ao assistente").
Future<void> abrirArtigo(BuildContext context, String topico) async {
  final shell = HomeShell.of(context);
  final saida = await Navigator.of(context).push<SaidaArtigo>(
    MaterialPageRoute(builder: (_) => ArtigoScreen(topico: topico)),
  );
  switch (saida) {
    case SaidaArtigo.inicio:
      shell.irPara(Aba.inicio);
    case SaidaArtigo.chat:
      shell.abrirChat();
    case null:
      break;
  }
}

class ArtigoScreen extends StatelessWidget {
  const ArtigoScreen({super.key, required this.topico});

  final String topico;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final estado = AppScope.of(context);
    final a = artigos[topico] ?? artigos['primaria']!;
    final salvo = estado.estaSalvo(a.topico);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: CuidaCores.azul,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                      textStyle: t.sans(15, peso: FontWeight.w500),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    label: const Text('Aprenda'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: salvo ? 'Remover dos salvos' : 'Salvar conteúdo',
                    isSelected: salvo,
                    color: CuidaCores.azul,
                    onPressed: () => estado.alternarSalvo(a.topico),
                    icon: const Icon(Icons.bookmark_border_rounded),
                    selectedIcon: const Icon(Icons.bookmark_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ir para o início',
                    color: CuidaCores.azul,
                    onPressed: () => Navigator.pop(context, SaidaArtigo.inicio),
                    icon: const Icon(Icons.home_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                children: [
                  Text('${a.categoria} · Conteúdo educativo',
                      style: t.sans(13.5, peso: FontWeight.w600, cor: CuidaCores.verde700)),
                  const SizedBox(height: 14),
                  Semantics(header: true, child: Text(a.titulo, style: t.serif(34, lh: 39, tracking: -0.015))),
                  const SizedBox(height: 14),
                  Text(a.tempo, style: t.sans(13.5, cor: t.mut)),
                  const SizedBox(height: 18),
                  Text(a.lead, style: t.sans(20, lh: 29)),
                  const SizedBox(height: 32),
                  _DiagramaNivel(ativo: a.nivelAtivo, rotulo: a.diagramaRotulo),
                  for (final s in a.secoes) ...[
                    const SizedBox(height: 32),
                    Semantics(header: true, child: Text(s.titulo, style: t.serif(24, lh: 29))),
                    for (final p in s.paragrafos) ...[
                      const SizedBox(height: 12),
                      Text(p, style: t.sans(16.5, lh: 27)),
                    ],
                    if (s.itens.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ListaMarcadores(itens: s.itens),
                    ],
                  ],
                  const SizedBox(height: 32),
                  CartaoTint(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(a.destaqueTitulo, style: t.sans(14, peso: FontWeight.w600, cor: CuidaCores.verdeTexto)),
                        const SizedBox(height: 6),
                        Text(a.destaque, style: t.serif(19, lh: 27, peso: FontWeight.w400)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Material(
                    color: CuidaCores.azul,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, SaidaArtigo.chat),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ficou com alguma dúvida?', style: t.serif(19, cor: Colors.white)),
                                  const SizedBox(height: 3),
                                  Text('Pergunte ao assistente sobre este tema',
                                      style: t.sans(13.5, lh: 19, cor: CuidaCores.sobreAzul)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(color: CuidaCores.verde, shape: BoxShape.circle),
                              child: const Icon(Icons.chat_bubble_outline_rounded,
                                  size: 20, color: CuidaCores.tintaEscura),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(header: true, child: Text('Referências oficiais', style: t.serif(22))),
                  const SizedBox(height: 12),
                  for (final r in a.refs) LinkReferencia(referencia: r, vertical: 14),
                  const SizedBox(height: 32),
                  BotaoSecundario('Voltar para Aprenda', onPressed: () => Navigator.pop(context)),
                  const SizedBox(height: 6),
                  Center(
                    child: BotaoLink('Ir para o início',
                        tamanho: 15, onPressed: () => Navigator.pop(context, SaidaArtigo.inicio)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Onde este nível se encaixa": Primária ⇄ Secundária ⇄ Terciária.
class _DiagramaNivel extends StatelessWidget {
  const _DiagramaNivel({required this.ativo, required this.rotulo});

  final int ativo;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    const nomes = ['Primária', 'Secundária', 'Terciária'];
    return Cartao(
      raio: 22,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text('Onde este nível se encaixa', style: t.sans(14, peso: FontWeight.w600, cor: CuidaCores.azul)),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: rotulo,
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < nomes.length; i++) ...[
                  if (i > 0)
                    const SizedBox(
                      width: 22,
                      height: 44,
                      child: Icon(Icons.swap_horiz_rounded, size: 18, color: CuidaCores.verde700),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == ativo ? CuidaCores.azul : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CuidaCores.azul),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                nomes[i],
                                style: t.sans(12.5,
                                    peso: FontWeight.w600, cor: i == ativo ? Colors.white : CuidaCores.azul),
                              ),
                            ),
                          ),
                        ),
                        if (i == ativo) ...[
                          const SizedBox(height: 6),
                          Text('Este conteúdo',
                              style: t.sans(11.5, peso: FontWeight.w600, cor: CuidaCores.verdeTexto)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text('Os serviços se comunicam nos dois sentidos: há encaminhamento e retorno.',
                style: t.sans(13, lh: 19, cor: t.mut)),
          ),
        ],
      ),
    );
  }
}
