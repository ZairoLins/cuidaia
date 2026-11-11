import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../services/links.dart';
import '../theme/cuida_tema.dart';
import 'botoes.dart';

/// Cartão branco com borda fina (#E2E7E9) e cantos de 14 px; sem sombra.
class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.raio = CuidaRaio.cartao,
    this.cor = Colors.white,
    this.onTap,
    this.sombra = true,
    this.borda,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double raio;
  final Color cor;
  final VoidCallback? onTap;

  /// Mantido por compatibilidade: `false` tira a borda padrão.
  final bool sombra;
  final BoxBorder? borda;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final br = BorderRadius.circular(raio);
    Widget conteudo = Padding(padding: padding, child: child);
    if (onTap != null) conteudo = InkWell(onTap: onTap, borderRadius: br, child: conteudo);
    return Container(
      foregroundDecoration: BoxDecoration(borderRadius: br, border: borda ?? (sombra ? t.contornoCartao : null)),
      child: Material(color: cor, borderRadius: br, clipBehavior: Clip.antiAlias, child: conteudo),
    );
  }
}

/// Tipos de aviso do sistema: cada estado tem cor própria.
enum TipoAviso {
  sucesso(
    CuidaCores.sucesso,
    CuidaCores.sucessoFundo,
    CuidaCores.sucessoLinha,
    CuidaCores.sucessoTexto,
    Icons.check_rounded,
  ),
  alerta(
    CuidaCores.alerta,
    CuidaCores.alertaFundo,
    CuidaCores.alertaLinha,
    CuidaCores.alertaTexto,
    Icons.warning_amber_rounded,
  ),
  erro(CuidaCores.erro, CuidaCores.erroFundo, CuidaCores.erroLinha, CuidaCores.erroTexto, Icons.error_outline_rounded),
  info(CuidaCores.info, CuidaCores.infoFundo, CuidaCores.infoLinha, CuidaCores.infoTexto, Icons.info_outline_rounded),
  destaque(
    CuidaCores.acao,
    CuidaCores.verde50,
    CuidaCores.verde100,
    CuidaCores.acaoEscuro,
    Icons.lightbulb_outline_rounded,
  );

  const TipoAviso(this.cor, this.fundo, this.linha, this.texto, this.icone);
  final Color cor;
  final Color fundo;
  final Color linha;
  final Color texto;
  final IconData icone;
}

/// Aviso com ícone, fundo e borda do estado (cantos de 10 px).
class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.tipo, required this.texto, this.titulo, this.icone, this.acao});

  final TipoAviso tipo;
  final String texto;

  /// Começo em negrito (ex.: "Sucesso.").
  final String? titulo;
  final IconData? icone;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final estilo = t.sans(14, lh: 21, cor: tipo.texto);
    return Semantics(
      liveRegion: tipo == TipoAviso.erro || tipo == TipoAviso.sucesso,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: t.altoContraste ? Colors.white : tipo.fundo,
          borderRadius: BorderRadius.circular(CuidaRaio.botao),
          border: Border.all(color: t.altoContraste ? CuidaCores.tinta : tipo.linha, width: t.altoContraste ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icone ?? tipo.icone, size: 18, color: tipo.cor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (titulo != null)
                          TextSpan(
                            text: '$titulo ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        TextSpan(text: texto),
                      ],
                    ),
                    style: estilo,
                  ),
                ),
              ],
            ),
            if (acao != null) ...[const SizedBox(height: 12), acao!],
          ],
        ),
      ),
    );
  }
}

/// Destaque editorial (verde 50 com borda verde 100).
class CartaoTint extends StatelessWidget {
  const CartaoTint({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Cartao(
      cor: t.tint,
      raio: 12,
      borda: Border.all(
        color: t.altoContraste ? CuidaCores.tinta : CuidaCores.verde100,
        width: t.altoContraste ? 1.5 : 1,
      ),
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Selo pequeno (cantos de 6 px): "Resposta gerada por IA", "Fonte oficial", "EMERGÊNCIA".
class Selo extends StatelessWidget {
  const Selo(
    this.texto, {
    super.key,
    this.cor = CuidaCores.acaoEscuro,
    this.fundo = CuidaCores.verde50,
    this.icone,
    this.forte = false,
  });

  final String texto;
  final Color cor;
  final Color fundo;
  final IconData? icone;
  final bool forte;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.altoContraste ? Colors.white : fundo,
        borderRadius: BorderRadius.circular(CuidaRaio.selo),
        border: t.altoContraste ? Border.all(color: cor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 13, color: cor), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              texto,
              style: t.sans(12, lh: 16, peso: forte ? FontWeight.w800 : FontWeight.w700, cor: cor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Número do nível de atenção num quadrado colorido (1 verde, 2 azul, 3 roxo).
class NumeroNivel extends StatelessWidget {
  const NumeroNivel(this.indice, {super.key, this.tamanho = 32});

  /// 0, 1 ou 2.
  final int indice;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final i = indice.clamp(0, 2);
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.altoContraste ? Colors.white : CuidaCores.nivelFundo[i],
        borderRadius: BorderRadius.circular(8),
        border: t.altoContraste ? Border.all(color: CuidaCores.tinta, width: 1.5) : null,
      ),
      child: Text(
        '${i + 1}',
        style: t.sans(13, peso: FontWeight.w800, cor: CuidaCores.nivelTexto[i]),
      ),
    );
  }
}

/// Chip tocável (36 px, cantos de 8 px). `destaque` usa o verde 50.
class ChipCuida extends StatelessWidget {
  const ChipCuida(this.texto, {super.key, required this.onPressed, this.destaque = false, this.iconeFim});

  final String texto;
  final VoidCallback? onPressed;
  final bool destaque;
  final IconData? iconeFim;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: destaque ? CuidaCores.acaoEscuro : CuidaCores.tinta,
        backgroundColor: destaque ? CuidaCores.verde50 : Colors.white,
        side: BorderSide(color: destaque ? CuidaCores.verde100 : t.borda, width: t.larguraBorda),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: CuidaRaio.formaChip,
        textStyle: t.sans(13.5, peso: destaque ? FontWeight.w700 : FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(texto)),
          if (iconeFim != null) ...[const SizedBox(width: 6), Icon(iconeFim, size: 13, color: CuidaCores.info)],
        ],
      ),
    );
  }
}

/// Coluna com separadores finos entre os itens.
class ListaSeparada extends StatelessWidget {
  const ListaSeparada({super.key, required this.children, this.linhaNoTopo = false, this.linhaNoFim = false});

  final List<Widget> children;
  final bool linhaNoTopo;
  final bool linhaNoFim;

  @override
  Widget build(BuildContext context) {
    final linha = Divider(height: 1, thickness: 1, color: context.tema.linha);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (linhaNoTopo) linha,
        for (var i = 0; i < children.length; i++) ...[if (i > 0) linha, children[i]],
        if (linhaNoFim) linha,
      ],
    );
  }
}

/// Lista com marca de verificação verde, como nos artigos do protótipo.
class ListaMarcadores extends StatelessWidget {
  const ListaMarcadores({
    super.key,
    required this.itens,
    this.cor = CuidaCores.acao,
    this.corLinha,
    this.tamanho = 15,
    this.lh = 22,
    this.vertical = 3,
  });

  final List<String> itens;
  final Color cor;

  /// Mantido por compatibilidade (o estilo 2.0 não usa linhas entre itens).
  final Color? corLinha;
  final double tamanho;
  final double lh;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in itens)
          Padding(
            padding: EdgeInsets.symmetric(vertical: vertical),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: (lh - 15) / 2),
                  child: Icon(Icons.check_rounded, size: 15, color: cor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: t.sans(tamanho, lh: lh, cor: t.corpo),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Link para documento oficial, com ícone de abrir fora do app.
class LinkReferencia extends StatelessWidget {
  const LinkReferencia({super.key, required this.referencia, this.vertical = 14});

  final Referencia referencia;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => abrirLink(context, referencia.url),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: vertical),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.linha)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.description_outlined, size: 18, color: t.mut),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referencia.titulo,
                      style: t.sans(14.5, lh: 20, peso: FontWeight.w700, cor: CuidaCores.info),
                    ),
                    const SizedBox(height: 2),
                    Text(referencia.descricao, style: t.sans(13, lh: 19, cor: t.mut)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.north_east_rounded, size: 15, color: CuidaCores.info),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha de lista navegável (ícone, título, descrição e chevron), mínimo de 56 px.
class LinhaNavegacao extends StatelessWidget {
  const LinhaNavegacao({
    super.key,
    required this.titulo,
    this.descricao,
    this.icone,
    this.inicio,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 14, 8),
    this.alturaMinima = 56,
    this.tituloEstilo,
  });

  final String titulo;
  final String? descricao;
  final IconData? icone;
  final Widget? inicio;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double alturaMinima;
  final TextStyle? tituloEstilo;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: alturaMinima),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (icone != null) ...[Icon(icone, size: 20, color: t.mut), const SizedBox(width: 12)],
              if (inicio != null) ...[inicio!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: tituloEstilo ?? t.sans(15, lh: 21, peso: FontWeight.w700, cor: CuidaCores.tinta),
                    ),
                    if (descricao != null && descricao!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(descricao!, style: t.sans(13, lh: 18, cor: t.mut)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, size: 20, color: CuidaCores.apoioClaro),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor acessível com marca de ativo (nunca só a cor).
class LinhaInterruptor extends StatelessWidget {
  const LinhaInterruptor({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.onChanged,
  });

  final String titulo;
  final String descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final duracao = t.duracao(const Duration(milliseconds: 180));
    return MergeSemantics(
      child: Semantics(
        toggled: valor,
        child: InkWell(
          onTap: () => onChanged(!valor),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: t.sans(15, lh: 21, peso: FontWeight.w700, cor: CuidaCores.tinta),
                        ),
                        const SizedBox(height: 1),
                        Text(descricao, style: t.sans(13, lh: 18, cor: t.mut)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  AnimatedContainer(
                    duration: duracao,
                    width: 46,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: valor ? CuidaCores.acao : CuidaCores.bordaCampo,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedAlign(
                      duration: duracao,
                      alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: valor ? const Icon(Icons.check_rounded, size: 13, color: CuidaCores.acao) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trecho de texto que mistura partes simples e links tocáveis.
class TrechoTexto {
  const TrechoTexto(this.texto, {this.onTap, this.negrito = false});
  final String texto;
  final VoidCallback? onTap;
  final bool negrito;
}

class TextoComLinks extends StatefulWidget {
  const TextoComLinks({
    super.key,
    required this.trechos,
    required this.estilo,
    this.corLink = CuidaCores.acao,
    this.alinhamento = TextAlign.start,
    this.sublinhado = false,
  });

  final List<TrechoTexto> trechos;
  final TextStyle estilo;
  final Color corLink;
  final TextAlign alinhamento;
  final bool sublinhado;

  @override
  State<TextoComLinks> createState() => _TextoComLinksState();
}

class _TextoComLinksState extends State<TextoComLinks> {
  final List<TapGestureRecognizer> _reconhecedores = [];

  void _limpar() {
    for (final r in _reconhecedores) {
      r.dispose();
    }
    _reconhecedores.clear();
  }

  @override
  void dispose() {
    _limpar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _limpar();
    return Text.rich(
      TextSpan(
        children: [
          for (final trecho in widget.trechos)
            if (trecho.onTap != null)
              TextSpan(
                text: trecho.texto,
                style: widget.estilo.copyWith(
                  color: widget.corLink,
                  fontWeight: FontWeight.w700,
                  decoration: widget.sublinhado ? TextDecoration.underline : null,
                  decorationColor: widget.corLink,
                ),
                recognizer: (TapGestureRecognizer()..onTap = trecho.onTap).also(_reconhecedores.add),
              )
            else
              TextSpan(
                text: trecho.texto,
                style: trecho.negrito ? widget.estilo.copyWith(fontWeight: FontWeight.w700) : null,
              ),
        ],
      ),
      style: widget.estilo,
      textAlign: widget.alinhamento,
    );
  }
}

extension _Also<T> on T {
  T also(void Function(T) fn) {
    fn(this);
    return this;
  }
}

/// Avatar do usuário: a foto, se houver, ou as iniciais sobre petróleo.
class AvatarIniciais extends StatelessWidget {
  const AvatarIniciais({super.key, required this.iniciais, this.foto, this.tamanho = 52});

  final String iniciais;
  final Uint8List? foto;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: CuidaCores.petroleo, shape: BoxShape.circle),
        child: foto != null
            ? Image.memory(foto!, width: tamanho, height: tamanho, fit: BoxFit.cover, gaplessPlayback: true)
            : Text(iniciais, style: context.tema.titulo(tamanho * 0.35, cor: Colors.white, tracking: 0)),
      ),
    );
  }
}

/// Aviso discreto com ícone à esquerda (texto de apoio).
class NotaApoio extends StatelessWidget {
  const NotaApoio({super.key, required this.texto, this.icone = Icons.lock_outline_rounded, this.tamanho = 13});

  final String texto;
  final IconData icone;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icone, size: 16, color: t.mut),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: t.sans(tamanho, lh: tamanho * 1.46, cor: t.mut),
          ),
        ),
      ],
    );
  }
}

/// Confirmação de sucesso ("Alterações salvas").
class AvisoSucesso extends StatelessWidget {
  const AvisoSucesso({super.key, required this.texto, this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Aviso(tipo: TipoAviso.sucesso, texto: texto, acao: acao);
}

/// Cabeçalho simples com botão voltar, usado nas telas internas.
class CabecalhoVoltar extends StatelessWidget {
  const CabecalhoVoltar({super.key, this.onVoltar});

  final VoidCallback? onVoltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: BotaoVoltar(onPressed: onVoltar),
      ),
    );
  }
}

/// Estrutura das telas internas: voltar, título (26/32, 800), apoio e conteúdo rolável.
class TelaInterna extends StatelessWidget {
  const TelaInterna({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.children,
    this.espaco = 24,
    this.onVoltar,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final double espaco;
  final VoidCallback? onVoltar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CabecalhoVoltar(onVoltar: onVoltar),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                    children: [
                      Semantics(header: true, child: Text(titulo, style: t.titulo(26, lh: 32))),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 6),
                        Text(subtitulo!, style: t.sans(14.5, lh: 21, cor: t.mut)),
                      ],
                      for (final c in children) ...[SizedBox(height: espaco), c],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rótulo de seção em caixa alta ("CONTA", "PREFERÊNCIAS"); `forte` usa o título de seção.
class RotuloSecao extends StatelessWidget {
  const RotuloSecao(this.texto, {super.key, this.forte = false});

  final String texto;
  final bool forte;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: forte ? 0 : 2),
        child: forte
            ? Text(texto, style: t.titulo(17, lh: 24, tracking: 0))
            // O leitor de tela recebe o texto normal, não soletrado em maiúsculas.
            : Text(texto.toUpperCase(), semanticsLabel: texto, style: t.legenda()),
      ),
    );
  }
}

/// Mensagem de erro de um formulário (resposta do servidor ou validação),
/// anunciada pelo leitor de tela assim que aparece.
class MensagemErro extends StatelessWidget {
  const MensagemErro(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        texto,
        style: context.tema.sans(14, lh: 21, peso: FontWeight.w500, cor: CuidaCores.erro),
      ),
    );
  }
}

/// Alça no topo das folhas inferiores ("Sair da conta?", "Recuperar senha").
class AlcaFolha extends StatelessWidget {
  const AlcaFolha({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: CuidaCores.bordaCampo, borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
