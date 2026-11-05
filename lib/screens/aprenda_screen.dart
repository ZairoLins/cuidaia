import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'artigo_screen.dart';

class AprendaScreen extends StatelessWidget {
  const AprendaScreen({super.key});

  Future<void> _buscar(BuildContext context) async {
    final topico = await showSearch<String?>(context: context, delegate: _BuscaConteudos());
    if (topico != null && context.mounted) await abrirArtigo(context, topico);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 16, 0),
            child: Row(
              children: [
                Expanded(child: Text('Aprenda', style: t.sans(15, peso: FontWeight.w500, cor: t.mut))),
                IconButton(
                  tooltip: 'Buscar conteúdos',
                  color: CuidaCores.azul,
                  onPressed: () => _buscar(context),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text('Entenda como a rede de saúde funciona', style: t.serif(34, lh: 39, tracking: -0.015)),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  const TextSpan(children: [
                    TextSpan(
                        text:
                            'O SUS reúne serviços muito diferentes — de unidades perto da sua casa a hospitais especializados. Na '),
                    TextSpan(text: 'Rede de Atenção à Saúde (RAS)', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(
                        text:
                            ', eles trabalham juntos, trocam informações e organizam o caminho de cada pessoa conforme a necessidade.'),
                  ]),
                  style: t.sans(16, lh: 26),
                ),
                const SizedBox(height: 44),
                const _MapaRede(),
                const SizedBox(height: 20),
                CartaoTint(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.lightbulb_outline_rounded, size: 20, color: CuidaCores.verde700),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text.rich(
                          const TextSpan(children: [
                            TextSpan(text: 'A UBS é a porta de entrada '),
                            TextSpan(text: 'preferencial', style: TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(
                                text:
                                    ', mas não a única. Em urgências, UPA 24h, pronto-socorro e SAMU 192 recebem você diretamente.'),
                          ]),
                          style: t.sans(15, lh: 23, cor: CuidaCores.azul),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
                _TituloSecao('Os três níveis de atenção'),
                const SizedBox(height: 14),
                for (final n in niveisAtencao) ...[
                  _CartaoNivel(nivel: n),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 30),
                _TituloSecao('Como esses serviços se conectam?'),
                const SizedBox(height: 14),
                for (var i = 0; i < conexoesRede.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: t.linha))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('0${i + 1}',
                                style: t.sans(13, peso: FontWeight.w600, cor: CuidaCores.verde700)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conexoesRede[i].titulo,
                                  style: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul)),
                              const SizedBox(height: 4),
                              Text(conexoesRede[i].descricao, style: t.sans(14.5, lh: 22, cor: t.mut)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 44),
                _TituloSecao('Exemplo de percurso'),
                const SizedBox(height: 6),
                Text('Situação ilustrativa e fictícia: seu João, 58 anos.', style: t.sans(14, lh: 21, cor: t.mut)),
                const SizedBox(height: 16),
                for (var i = 0; i < percursoExemplo.length; i++)
                  _PassoPercurso(item: percursoExemplo[i], ultimo: i == percursoExemplo.length - 1),
                Text(
                  'Cada caso é diferente. Em uma emergência, o cuidado pode começar no SAMU ou no hospital.',
                  style: t.sans(14, lh: 21, cor: t.mut, estilo: FontStyle.italic),
                ),
                const SizedBox(height: 44),
                _TituloSecao('Fontes e referências'),
                const SizedBox(height: 12),
                for (final r in referenciasAprenda) LinkReferencia(referencia: r),
                const SizedBox(height: 8),
                Text(
                  'Conteúdo educativo elaborado a partir de documentos oficiais. Revisado em [DATA DA REVISÃO].',
                  style: t.sans(13, lh: 19, cor: t.mut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(texto, style: context.tema.serif(26, lh: 31)));
}

/// "Uma rede, não uma escada": Primária coordena e se comunica com Secundária e Terciária.
class _MapaRede extends StatelessWidget {
  const _MapaRede();

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    Widget caixa(String titulo, String sub) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.bordaBotao, width: t.larguraBorda),
          ),
          child: Column(
            children: [
              Text(titulo, style: t.sans(14.5, peso: FontWeight.w600, cor: CuidaCores.azul)),
              const SizedBox(height: 2),
              Text(sub, textAlign: TextAlign.center, style: t.sans(12.5, cor: t.mut)),
            ],
          ),
        );

    return Cartao(
      raio: 24,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Semantics(header: true, child: Text('Uma rede, não uma escada', style: t.serif(21))),
          ),
          const SizedBox(height: 16),
          Semantics(
            label:
                'Diagrama: a Atenção Primária coordena o cuidado e se comunica nos dois sentidos com a Atenção Secundária e a Terciária, que também se comunicam entre si.',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: CuidaCores.azul, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.home_work_outlined, size: 24, color: CuidaCores.verdeClaro),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Atenção Primária', style: t.sans(15.5, peso: FontWeight.w600, cor: Colors.white)),
                          const SizedBox(height: 1),
                          Text('Coordena o cuidado', style: t.sans(13, cor: CuidaCores.sobreAzul)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(child: Icon(Icons.swap_vert_rounded, size: 22, color: CuidaCores.verde700)),
                      Expanded(child: Icon(Icons.swap_vert_rounded, size: 22, color: CuidaCores.verde700)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: caixa('Secundária', 'Especialidades')),
                    const SizedBox(
                      width: 28,
                      child: Icon(Icons.swap_horiz_rounded, size: 20, color: CuidaCores.verde700),
                    ),
                    Expanded(child: caixa('Terciária', 'Alta complexidade')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              'Setas nos dois sentidos: há encaminhamento e retorno, organizados pela regulação e pela troca de informações.',
              style: t.sans(13.5, lh: 20, cor: t.mut),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoNivel extends StatelessWidget {
  const _CartaoNivel({required this.nivel});

  final NivelAtencao nivel;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Cartao(
      raio: 22,
      onTap: () => abrirArtigo(context, nivel.topico),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(nivel.numero, style: t.serif(30, lh: 30, cor: CuidaCores.verde700)),
              const Spacer(),
              Text(nivel.rotulo, style: t.sans(13, peso: FontWeight.w500, cor: t.mut)),
            ],
          ),
          const SizedBox(height: 10),
          Text(nivel.titulo, style: t.serif(23, lh: 28)),
          const SizedBox(height: 10),
          Text(nivel.descricao, style: t.sans(15, lh: 23)),
          const SizedBox(height: 10),
          Text(nivel.exemplos, style: t.sans(13.5, lh: 20, cor: t.mut)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Saiba mais', style: t.sans(14.5, peso: FontWeight.w600, cor: CuidaCores.verde700)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: CuidaCores.verde700),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassoPercurso extends StatelessWidget {
  const _PassoPercurso({required this.item, required this.ultimo});

  final ItemTexto item;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ultimo ? CuidaCores.verde700 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: CuidaCores.verde700, width: 2),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(width: 1.5, color: ultimo ? Colors.transparent : CuidaCores.bordaBotao),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titulo, style: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul)),
                  const SizedBox(height: 4),
                  Text(item.descricao, style: t.sans(14.5, lh: 22, cor: t.mut)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Busca simples entre os conteúdos educativos.
class _BuscaConteudos extends SearchDelegate<String?> {
  _BuscaConteudos() : super(searchFieldLabel: 'Buscar conteúdos');

  List<Artigo> _resultados() {
    final q = query.trim().toLowerCase();
    return artigos.values.where((a) {
      if (q.isEmpty) return true;
      final texto = [a.titulo, a.categoria, a.lead, ...a.secoes.expand((s) => [s.titulo, ...s.paragrafos, ...s.itens])]
          .join(' ')
          .toLowerCase();
      return texto.contains(q);
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(tooltip: 'Limpar', onPressed: () => query = '', icon: const Icon(Icons.close_rounded)),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Voltar',
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final t = context.tema;
    final itens = _resultados();
    if (itens.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Nenhum conteúdo encontrado para "$query".', style: t.sans(15, cor: t.mut)),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        for (final a in itens)
          LinhaNavegacao(
            titulo: a.titulo,
            descricao: '${a.categoria} · ${a.tempo}',
            tituloEstilo: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul),
            padding: const EdgeInsets.symmetric(vertical: 16),
            onTap: () => close(context, a.topico),
          ),
      ],
    );
  }
}
