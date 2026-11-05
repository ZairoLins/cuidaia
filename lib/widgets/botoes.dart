import 'package:flutter/material.dart';

import '../theme/cuida_tema.dart';

/// Botão principal em pílula (verde-água 700). Ocupa toda a largura.
class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario(
    this.texto, {
    super.key,
    required this.onPressed,
    this.cor = CuidaCores.verde700,
    this.altura = 56,
    this.icone,
    this.carregando = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final Color cor;
  final double altura;
  final IconData? icone;

  /// Mostra um indicador e bloqueia novos toques enquanto a ação roda.
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    if (carregando) {
      return Semantics(
        label: '$texto, aguarde',
        button: true,
        enabled: false,
        child: ExcludeSemantics(
          child: FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              disabledBackgroundColor: cor.withValues(alpha: 0.7),
              minimumSize: Size.fromHeight(altura),
              shape: const StadiumBorder(),
            ),
            child: const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: CuidaCores.desativado,
        disabledForegroundColor: Colors.white,
        minimumSize: Size.fromHeight(altura),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: t.sans(altura < 56 ? 15.5 : 16, peso: FontWeight.w600),
      ),
      child: icone == null
          ? Text(texto, textAlign: TextAlign.center)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icone, size: 19), const SizedBox(width: 10), Flexible(child: Text(texto))],
            ),
    );
  }
}

/// Botão secundário com contorno. Ocupa toda a largura.
class BotaoSecundario extends StatelessWidget {
  const BotaoSecundario(this.texto, {super.key, required this.onPressed, this.altura = 56});

  final String texto;
  final VoidCallback? onPressed;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CuidaCores.azul,
        side: BorderSide(color: t.bordaBotao, width: t.larguraBorda),
        minimumSize: Size.fromHeight(altura),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: t.sans(altura < 56 ? 15 : 16, peso: FontWeight.w600),
      ),
      child: Text(texto, textAlign: TextAlign.center),
    );
  }
}

/// Botão compacto (44 px) com contorno, para ações dentro de cartões.
class BotaoCompacto extends StatelessWidget {
  const BotaoCompacto(
    this.texto, {
    super.key,
    required this.onPressed,
    this.icone,
    this.destrutivo = false,
    this.preenchido = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool destrutivo;
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final cor = destrutivo ? CuidaCores.erro : CuidaCores.azul;
    final borda = destrutivo ? CuidaCores.erro : t.bordaBotao;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: cor,
        backgroundColor: preenchido ? Colors.white : Colors.transparent,
        side: BorderSide(color: borda, width: t.larguraBorda),
        minimumSize: const Size(0, 44),
        padding: EdgeInsets.fromLTRB(icone == null ? 18 : 14, 0, 18, 0),
        shape: const StadiumBorder(),
        textStyle: t.sans(14.5, peso: FontWeight.w600),
      ),
      child: icone == null
          ? Text(texto)
          : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icone, size: 18), const SizedBox(width: 8), Text(texto)]),
    );
  }
}

/// Link de texto (verde-água 700, sublinhado opcional) com área de toque de 44 px.
class BotaoLink extends StatelessWidget {
  const BotaoLink(
    this.texto, {
    super.key,
    required this.onPressed,
    this.cor = CuidaCores.verde700,
    this.tamanho = 14,
    this.sublinhado = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final Color cor;
  final double tamanho;
  final bool sublinhado;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: cor,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: t.sans(tamanho, peso: FontWeight.w600, decoracao: sublinhado ? TextDecoration.underline : null),
      ),
      child: Text(texto),
    );
  }
}

/// Destaque sobre fundo azul: pílula verde-água com seta em círculo escuro.
class BotaoDestaque extends StatelessWidget {
  const BotaoDestaque(this.texto, {super.key, required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Material(
      color: CuidaCores.verde,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(24, 0, 8, 0),
          child: Row(
            children: [
              Expanded(child: Text(texto, style: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.tintaEscura))),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: CuidaCores.tintaEscura, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, size: 18, color: CuidaCores.verdeClaro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão "voltar" circular de 44 px.
class BotaoVoltar extends StatelessWidget {
  const BotaoVoltar({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Voltar',
      color: CuidaCores.azul,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
    );
  }
}
