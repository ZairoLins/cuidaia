import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../services/links.dart';
import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'home_shell.dart';

/// Destino escolhido ao sair de um artigo.
enum SaidaArtigo { inicio, chat }

/// Abre um artigo e trata o retorno ("Ir para o início" ou "Pergunte ao assistente").
Future<void> abrirArtigo(BuildContext context, String topico) async {
  final shell = HomeShell.of(context);
  final artigo = artigos[topico];
  if (artigo != null) AppScope.read(context).leituraIniciada(topico: topico, titulo: artigo.titulo);
  final saida = await Navigator.of(context)
      .push<SaidaArtigo>(MaterialPageRoute(builder: (_) => ArtigoScreen(topico: topico)));
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
    final nivel = a.nivelAtivo.clamp(0, 2);
    final importante = a.destaqueTitulo.toLowerCase().contains('importante');

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: CuidaCores.tinta,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                          shape: CuidaRaio.formaBotao,
                          textStyle: t.sans(14.5, peso: FontWeight.w700),
                        ),
                        icon: const Icon(Icons.chevron_left_rounded, size: 24),
                        label: const Text('Aprenda'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: salvo ? 'Remover dos salvos' : 'Salvar conteúdo',
                        isSelected: salvo,
                        color: CuidaCores.tinta,
                        style: IconButton.styleFrom(shape: CuidaRaio.formaBotao),
                        onPressed: () => estado.alternarSalvo(a.topico),
                        icon: const Icon(Icons.bookmark_border_rounded, size: 21),
                        selectedIcon: const Icon(Icons.bookmark_rounded, size: 21),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  // Guarda o progresso para o "Continue lendo". Perto do fim, conta
                  // como lido e cancela o lembrete "Continuar leitura".
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      final m = n.metrics;
                      if (n.depth != 0) return false;
                      if (m.extentAfter < 400) {
                        estado.registrarProgresso(a.topico, 1);
                        estado.leituraConcluida(a.topico);
                      } else if (m.maxScrollExtent > 0) {
                        estado.registrarProgresso(a.topico, m.pixels / m.maxScrollExtent);
                      }
                      return false;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Selo(
                            '${a.categoria} · ${a.tempo}',
                            cor: CuidaCores.nivelTexto[nivel],
                            fundo: CuidaCores.nivelFundo[nivel],
                            forte: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(header: true, child: Text(a.titulo, style: t.titulo(24, lh: 30))),
                        const SizedBox(height: 8),
                        Text(a.lead, style: t.sans(16, lh: 25, cor: t.corpo)),
                        const SizedBox(height: 22),
                        _DiagramaNivel(ativo: nivel, rotulo: a.diagramaRotulo),
                        for (final s in a.secoes) ...[
                          const SizedBox(height: 22),
                          Semantics(header: true, child: Text(s.titulo, style: t.titulo(17, lh: 24, tracking: 0))),
                          for (final p in s.paragrafos) ...[
                            const SizedBox(height: 8),
                            Text(p, style: t.sans(15.5, lh: 24, cor: t.corpo)),
                          ],
                          if (s.itens.isNotEmpty) ...[const SizedBox(height: 8), ListaMarcadores(itens: s.itens)],
                        ],
                        const SizedBox(height: 22),
                        Aviso(
                          tipo: importante ? TipoAviso.alerta : TipoAviso.info,
                          titulo: '${a.destaqueTitulo}.'.replaceAll('?.', '?').replaceAll('..', '.'),
                          texto: a.destaque,
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () => Navigator.pop(context, SaidaArtigo.chat),
                              style: FilledButton.styleFrom(
                                backgroundColor: CuidaCores.acao,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: CuidaRaio.formaBotao,
                                textStyle: t.sans(14.5, peso: FontWeight.w700),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                              label: const Text('Perguntar ao assistente'),
                            ),
                            for (final r in a.refs)
                              Semantics(
                                link: true,
                                hint: r.descricao,
                                child: ChipCuida(
                                  r.titulo.replaceFirst('Portaria GM/MS nº ', 'Portaria '),
                                  iconeFim: Icons.north_east_rounded,
                                  onPressed: () => abrirLink(context, r.url),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: BotaoLink(
                            'Ir para o início',
                            onPressed: () => Navigator.pop(context, SaidaArtigo.inicio),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Onde este nível se encaixa": Primária ⇄ Secundária ⇄ Terciária, com o nível atual em petróleo.
class _DiagramaNivel extends StatelessWidget {
  const _DiagramaNivel({required this.ativo, required this.rotulo});

  final int ativo;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    const nomes = ['Primária', 'Secundária', 'Terciária'];
    return Cartao(
      raio: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ONDE ESTE NÍVEL SE ENCAIXA', semanticsLabel: 'Onde este nível se encaixa', style: t.legenda()),
          const SizedBox(height: 12),
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
                      child: Icon(Icons.swap_horiz_rounded, size: 18, color: CuidaCores.apoio),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == ativo ? CuidaCores.petroleo : Colors.white,
                            borderRadius: BorderRadius.circular(CuidaRaio.botao),
                            border: i == ativo ? null : Border.all(color: t.borda, width: t.larguraBorda),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                nomes[i],
                                style: t.sans(
                                  13,
                                  peso: FontWeight.w800,
                                  cor: i == ativo ? Colors.white : CuidaCores.tinta,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (i == ativo) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Este conteúdo',
                            style: t.sans(11.5, peso: FontWeight.w700, cor: CuidaCores.acaoEscuro),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
