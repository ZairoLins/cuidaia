import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../services/links.dart';
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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text('Aprenda', style: t.titulo(24, lh: 30))),
                        const SizedBox(height: 6),
                        Text('Como a Rede de Atenção à Saúde funciona.', style: t.sans(14.5, lh: 21, cor: t.mut)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Buscar conteúdos',
                    color: CuidaCores.tinta,
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CuidaRaio.botao),
                        side: BorderSide(color: t.linha, width: t.larguraBorda),
                      ),
                    ),
                    onPressed: () => _buscar(context),
                    icon: const Icon(Icons.search_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _MapaRede(),
              const SizedBox(height: 12),
              const Aviso(
                tipo: TipoAviso.info,
                titulo: 'A UBS é a porta de entrada preferencial,',
                texto: 'mas não a única. Em urgências, UPA 24h, pronto-socorro e SAMU 192 recebem você diretamente.',
              ),
              const SizedBox(height: 28),

              const RotuloSecao('Níveis de atenção'),
              const SizedBox(height: 10),
              Cartao(
                raio: 12,
                child: ListaSeparada(
                  children: [
                    for (final (i, n) in niveisAtencao.indexed)
                      LinhaNavegacao(
                        titulo: n.titulo,
                        descricao: n.resumo,
                        inicio: NumeroNivel(i),
                        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                        onTap: () => abrirArtigo(context, n.topico),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const RotuloSecao('Como se conectam'),
              const SizedBox(height: 12),
              _LinhaDoTempo(itens: conexoesRede),
              const SizedBox(height: 16),

              const RotuloSecao('Exemplo de percurso'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Situação ilustrativa e fictícia: seu João, 58 anos.',
                  style: t.sans(13.5, lh: 20, cor: t.mut),
                ),
              ),
              const SizedBox(height: 12),
              _LinhaDoTempo(itens: percursoExemplo),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Cada caso é diferente. Em uma emergência, o cuidado pode começar no SAMU ou no hospital.',
                  style: t.sans(13.5, lh: 20, cor: t.mut),
                ),
              ),
              const SizedBox(height: 28),

              const RotuloSecao('Saúde coletiva'),
              const SizedBox(height: 10),
              Cartao(
                raio: 12,
                child: LinhaNavegacao(
                  titulo: artigos['vigilancia']!.categoria,
                  descricao: 'Vacinação, controle de doenças e fiscalização',
                  inicio: const Icon(Icons.shield_outlined, size: 22, color: CuidaCores.tinta),
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  onTap: () => abrirArtigo(context, 'vigilancia'),
                ),
              ),
              const SizedBox(height: 28),

              const RotuloSecao('Fontes oficiais'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in referenciasAprenda)
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
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Conteúdo educativo elaborado a partir de documentos oficiais. Revisado em 7 de novembro de 2026.',
                  style: t.sans(12.5, lh: 18, cor: t.mut),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Uma rede, não uma escada": a Primária se comunica nos dois sentidos com as outras.
class _MapaRede extends StatelessWidget {
  const _MapaRede();

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    Widget caixa(String titulo) => Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CuidaRaio.botao),
        border: Border.all(color: t.borda, width: t.larguraBorda),
      ),
      child: Text(titulo, style: t.sans(14, peso: FontWeight.w800)),
    );
    const seta = Icon(Icons.swap_vert_rounded, size: 22, color: CuidaCores.apoio);

    return Cartao(
      raio: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Diagrama: a Atenção Primária se comunica nos dois sentidos com a Secundária e a Terciária, que também se comunicam entre si.',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CuidaCores.petroleo,
                    borderRadius: BorderRadius.circular(CuidaRaio.botao),
                  ),
                  child: Text(
                    'Atenção Primária',
                    style: t.sans(14.5, peso: FontWeight.w800, cor: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Expanded(child: seta),
                      Expanded(child: seta),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: caixa('Secundária')),
                    const SizedBox(width: 28, child: Icon(Icons.swap_horiz_rounded, size: 20, color: CuidaCores.apoio)),
                    Expanded(child: caixa('Terciária')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Os serviços se comunicam: há encaminhamento e retorno, organizados pela regulação.',
            style: t.sans(13, lh: 19, cor: t.mut),
          ),
        ],
      ),
    );
  }
}

/// Passos numerados ligados por uma linha; o último fica preenchido.
class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo({required this.itens});

  final List<ItemTexto> itens;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Column(
      children: [
        for (final (i, item) in itens.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == itens.length - 1 ? CuidaCores.acao : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: CuidaCores.acao, width: 1.5),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: t.sans(
                            11.5,
                            peso: FontWeight.w800,
                            cor: i == itens.length - 1 ? Colors.white : CuidaCores.acaoEscuro,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: i == itens.length - 1 ? Colors.transparent : CuidaCores.bordaCampo,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.titulo}. ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: item.descricao,
                            style: TextStyle(color: t.mut),
                          ),
                        ],
                      ),
                      style: t.sans(14.5, lh: 22, cor: CuidaCores.tinta),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
      final texto = [
        a.titulo,
        a.categoria,
        a.lead,
        ...a.secoes.expand((s) => [s.titulo, ...s.paragrafos, ...s.itens]),
      ].join(' ').toLowerCase();
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
    icon: const Icon(Icons.chevron_left_rounded, size: 26),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            onTap: () => close(context, a.topico),
          ),
      ],
    );
  }
}
