import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../services/links.dart';
import '../theme/cuida_tema.dart';
import 'botoes.dart';

/// Cartão branco com sombra suave (contorno no alto contraste).
class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.raio = 20,
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
  final bool sombra;
  final BoxBorder? borda;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final br = BorderRadius.circular(raio);
    Widget conteudo = Padding(padding: padding, child: child);
    if (onTap != null) conteudo = InkWell(onTap: onTap, borderRadius: br, child: conteudo);
    return Container(
      decoration: BoxDecoration(borderRadius: br, boxShadow: sombra ? t.sombra() : null),
      foregroundDecoration: BoxDecoration(borderRadius: br, border: borda ?? (sombra ? t.contornoCartao : null)),
      child: Material(color: cor, borderRadius: br, clipBehavior: Clip.antiAlias, child: conteudo),
    );
  }
}

/// Cartão verde suave de destaque editorial (branco com contorno no alto contraste).
class CartaoTint extends StatelessWidget {
  const CartaoTint({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Cartao(
      cor: t.tint,
      sombra: false,
      borda: t.altoContraste ? Border.all(color: CuidaCores.grafite, width: 1.5) : null,
      padding: padding,
      onTap: onTap,
      child: child,
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

/// Item de lista com marcador redondo e separador acima.
class ListaMarcadores extends StatelessWidget {
  const ListaMarcadores({
    super.key,
    required this.itens,
    this.cor = CuidaCores.verde700,
    this.corLinha,
    this.tamanho = 15.5,
    this.lh = 23,
    this.vertical = 12,
  });

  final List<String> itens;
  final Color cor;
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
          Container(
            padding: EdgeInsets.symmetric(vertical: vertical),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: corLinha ?? t.linha))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: (lh - 6) / 2),
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item, style: t.sans(tamanho, lh: lh))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Link para documento oficial, com ícone de abrir fora do app.
class LinkReferencia extends StatelessWidget {
  const LinkReferencia({super.key, required this.referencia, this.vertical = 16});

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
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.linha))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.description_outlined, size: 18, color: CuidaCores.azul),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(referencia.titulo, style: t.sans(15, lh: 21, peso: FontWeight.w600, cor: CuidaCores.azul)),
                    const SizedBox(height: 2),
                    Text(referencia.descricao, style: t.sans(13.5, lh: 20, cor: t.mut)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.open_in_new_rounded, size: 16, color: t.mut),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha de lista navegável (ícone, título, descrição e chevron).
class LinhaNavegacao extends StatelessWidget {
  const LinhaNavegacao({
    super.key,
    required this.titulo,
    this.descricao,
    this.icone,
    this.inicio,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 16, 10),
    this.alturaMinima = 62,
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
              if (icone != null) ...[
                Icon(icone, size: 22, color: CuidaCores.azul),
                const SizedBox(width: 14),
              ],
              if (inicio != null) ...[inicio!, const SizedBox(width: 16)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo, style: tituloEstilo ?? t.sans(15.5, peso: FontWeight.w500, cor: CuidaCores.azul)),
                    if (descricao != null && descricao!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(descricao!, style: t.sans(13.5, lh: 19, cor: t.mut)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, size: 22, color: t.mut),
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
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: t.sans(15.5, peso: FontWeight.w500, cor: CuidaCores.azul)),
                        const SizedBox(height: 3),
                        Text(descricao, style: t.sans(13, lh: 19, cor: t.mut)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  AnimatedContainer(
                    duration: duracao,
                    width: 52,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: valor ? CuidaCores.verde700 : CuidaCores.desativado,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedAlign(
                      duration: duracao,
                      alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: valor ? const Icon(Icons.check_rounded, size: 15, color: CuidaCores.verde700) : null,
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
    this.corLink = CuidaCores.azul,
    this.alinhamento = TextAlign.start,
  });

  final List<TrechoTexto> trechos;
  final TextStyle estilo;
  final Color corLink;
  final TextAlign alinhamento;

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
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: widget.corLink,
                ),
                recognizer: (TapGestureRecognizer()..onTap = trecho.onTap).also(_reconhecedores.add),
              )
            else
              TextSpan(
                text: trecho.texto,
                style: trecho.negrito ? widget.estilo.copyWith(fontWeight: FontWeight.w600) : null,
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

/// Avatar do usuário: a foto, se houver, ou as iniciais.
class AvatarIniciais extends StatelessWidget {
  const AvatarIniciais({super.key, required this.iniciais, this.foto, this.tamanho = 64});

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
        decoration: const BoxDecoration(color: CuidaCores.azul, shape: BoxShape.circle),
        child: foto != null
            ? Image.memory(foto!, width: tamanho, height: tamanho, fit: BoxFit.cover, gaplessPlayback: true)
            : Text(iniciais, style: context.tema.serif(tamanho * 0.375, cor: Colors.white)),
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
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icone, size: 16, color: t.mut)),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: t.sans(tamanho, lh: tamanho * 1.48, cor: t.mut))),
      ],
    );
  }
}

/// Mensagem de confirmação com fundo verde suave.
class AvisoSucesso extends StatelessWidget {
  const AvisoSucesso({super.key, required this.texto, this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, acao == null ? 12 : 0, 12, acao == null ? 12 : 0),
        decoration: BoxDecoration(
          color: t.tint,
          borderRadius: BorderRadius.circular(16),
          border: t.altoContraste ? Border.all(color: CuidaCores.grafite, width: 1.5) : null,
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20, color: CuidaCores.verde700),
            const SizedBox(width: 12),
            Expanded(child: Text(texto, style: t.sans(14.5, peso: FontWeight.w500, cor: CuidaCores.azul))),
            if (acao != null) acao!,
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho simples com botão voltar, usado nas telas internas.
class CabecalhoVoltar extends StatelessWidget {
  const CabecalhoVoltar({super.key, this.onVoltar});

  final VoidCallback? onVoltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Align(alignment: Alignment.centerLeft, child: BotaoVoltar(onPressed: onVoltar)),
    );
  }
}

/// Estrutura das telas internas: voltar, título em serifa, texto de apoio e conteúdo rolável.
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: [
                  Semantics(
                    header: true,
                    child: Text(titulo, style: t.serif(32, lh: 38, tracking: -0.015)),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 10),
                    Text(subtitulo!, style: t.sans(15, lh: 23, cor: t.mut)),
                  ],
                  for (final c in children) ...[SizedBox(height: espaco), c],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de seção pequeno em sans-serif (ex.: "Conta", "Preferências").
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
        padding: EdgeInsets.symmetric(horizontal: forte ? 0 : 4),
        child: Text(
          texto,
          style: forte
              ? t.sans(15, peso: FontWeight.w600, cor: CuidaCores.azul)
              : t.sans(13.5, peso: FontWeight.w500, cor: t.mut),
        ),
      ),
    );
  }
}
