import 'package:flutter/material.dart';

import '../theme/cuida_tema.dart';

/// Botão principal: verde de ação, texto branco 15/700, 48 px, cantos de 10 px.
/// Ocupa toda a largura. Use um por tela.
class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario(
    this.texto, {
    super.key,
    required this.onPressed,
    this.cor = CuidaCores.acao,
    this.altura = 48,
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
    // Pressionado/carregando: o tom 700 da mesma cor.
    final corCarregando = cor == CuidaCores.acao ? CuidaCores.acaoEscuro : cor;
    if (carregando) {
      return Semantics(
        label: '$texto, aguarde',
        button: true,
        enabled: false,
        child: ExcludeSemantics(
          child: FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              disabledBackgroundColor: corCarregando,
              minimumSize: Size.fromHeight(altura),
              shape: CuidaRaio.formaBotao,
            ),
            child: const SizedBox.square(
              dimension: 18,
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
        disabledBackgroundColor: CuidaCores.trilho,
        disabledForegroundColor: CuidaCores.apoioClaro,
        minimumSize: Size.fromHeight(altura),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: CuidaRaio.formaBotao,
        textStyle: t.sans(15, peso: FontWeight.w700),
      ).copyWith(overlayColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.12))),
      child: icone == null
          ? Text(texto, textAlign: TextAlign.center)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(texto)),
              ],
            ),
    );
  }
}

/// Botão secundário: branco com borda fina de campo. Ocupa toda a largura.
class BotaoSecundario extends StatelessWidget {
  const BotaoSecundario(this.texto, {super.key, required this.onPressed, this.altura = 48, this.icone});

  final String texto;
  final IconData? icone;
  final VoidCallback? onPressed;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CuidaCores.tinta,
        backgroundColor: Colors.white,
        side: BorderSide(color: t.bordaBotao, width: t.larguraBorda),
        minimumSize: Size.fromHeight(altura),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: CuidaRaio.formaBotao,
        textStyle: t.sans(15, peso: FontWeight.w700),
      ),
      child: icone == null
          ? Text(texto, textAlign: TextAlign.center)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 19, color: CuidaCores.acao),
                const SizedBox(width: 8),
                Flexible(child: Text(texto, textAlign: TextAlign.center)),
              ],
            ),
    );
  }
}

/// "Continuar com o Google" no tema claro das diretrizes da marca:
/// fundo branco, borda #747775, Roboto Medium e o "G" colorido.
class BotaoGoogle extends StatelessWidget {
  const BotaoGoogle({
    super.key,
    required this.onPressed,
    this.texto = 'Continuar com o Google',
    this.carregando = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final rotulo = carregando ? 'Conectando ao Google…' : texto;
    return Semantics(
      label: carregando ? '$texto, aguarde' : null,
      child: OutlinedButton(
        onPressed: carregando ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CuidaCores.googleTexto,
          disabledForegroundColor: CuidaCores.googleTexto,
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white,
          side: const BorderSide(color: CuidaCores.googleBorda),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: CuidaRaio.formaBotao,
          textStyle: CuidaTema.roboto(const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: carregando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: CuidaCores.googleTexto),
                    )
                  : const CustomPaint(size: Size.square(20), painter: _LogoGoogle()),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(rotulo, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

class _LogoGoogle extends CustomPainter {
  const _LogoGoogle();

  static const _azul = Color(0xFF4285F4);
  static const _verde = Color(0xFF34A853);
  static const _amarelo = Color(0xFFFBBC05);
  static const _vermelho = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final w = s * 0.2;
    final r = s / 2 - w / 2;
    final arco = Rect.fromCircle(center: c, radius: r);
    double g(double graus) => graus * 3.141592653589793 / 180;
    void parte(Color cor, double de, double ate) => canvas.drawArc(
      arco,
      g(de),
      g(ate - de),
      false,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );

    parte(_azul, 0, 45);
    parte(_verde, 45, 135);
    parte(_amarelo, 135, 210);
    parte(_vermelho, 210, 315);
    // Barra horizontal do "G".
    canvas.drawRect(Rect.fromLTRB(c.dx, c.dy - w / 2, c.dx + r + w / 2, c.dy + w / 2), Paint()..color = _azul);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Botão compacto (40 px, cantos de 8 px) para ações dentro de cartões.
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
    final cor = destrutivo ? CuidaCores.erroForte : CuidaCores.tinta;
    final borda = destrutivo ? CuidaCores.erro : t.bordaBotao;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: cor,
        backgroundColor: Colors.white,
        side: BorderSide(color: borda, width: t.larguraBorda),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.fromLTRB(icone == null ? 14 : 12, 0, 14, 0),
        shape: CuidaRaio.formaChip,
        textStyle: t.sans(14, peso: FontWeight.w700),
      ),
      child: icone == null
          ? Text(texto)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icone, size: 17), const SizedBox(width: 8), Text(texto)],
            ),
    );
  }
}

/// Link de texto no verde de ação, 700, com área de toque de 44 px.
class BotaoLink extends StatelessWidget {
  const BotaoLink(
    this.texto, {
    super.key,
    required this.onPressed,
    this.cor = CuidaCores.acao,
    this.tamanho = 13.5,
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
        shape: CuidaRaio.formaChip,
        textStyle: t.sans(tamanho, peso: FontWeight.w700, decoracao: sublinhado ? TextDecoration.underline : null),
      ),
      child: Text(texto),
    );
  }
}

/// Ação principal sobre um painel petróleo: botão menta com texto petróleo.
class BotaoDestaque extends StatelessWidget {
  const BotaoDestaque(this.texto, {super.key, required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: CuidaCores.menta,
        foregroundColor: CuidaCores.petroleo,
        minimumSize: const Size.fromHeight(48),
        shape: CuidaRaio.formaBotao,
        textStyle: t.sans(15, peso: FontWeight.w700),
      ),
      child: Text(texto),
    );
  }
}

/// "Cancelar" discreto, abaixo do botão principal de um formulário: fecha a tela.
class BotaoCancelar extends StatelessWidget {
  const BotaoCancelar({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        foregroundColor: CuidaCores.tinta,
        minimumSize: const Size.fromHeight(48),
        textStyle: context.tema.sans(15, peso: FontWeight.w600),
      ),
      child: const Text('Cancelar'),
    );
  }
}

/// Botão "voltar" de 44 px.
class BotaoVoltar extends StatelessWidget {
  const BotaoVoltar({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Voltar',
      color: CuidaCores.tinta,
      style: IconButton.styleFrom(shape: CuidaRaio.formaBotao),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: const Icon(Icons.chevron_left_rounded, size: 26),
    );
  }
}
