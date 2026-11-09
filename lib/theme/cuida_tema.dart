import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual 2.0 do CuidaIA: "clínico, calmo e confiável".
///
/// Uma família tipográfica (Manrope), cor usada só para significar algo
/// (ação, estado ou risco) e superfícies planas separadas por bordas finas.
/// Referência: protótipo "CuidaIA — Protótipo mobile" (Identidade visual 2.0).
abstract final class CuidaCores {
  // Verde Cuidado: só para ação (botões, links, seleção).
  static const verde50 = Color(0xFFE6F2EF); // fundos de seleção
  static const verde100 = Color(0xFFBFDDD6);
  static const verde300 = Color(0xFF5FB3A4);
  static const acao = Color(0xFF137567); // 600: 5,6:1 com texto branco
  static const acaoEscuro = Color(0xFF0F5F55); // 700: pressionado, texto sobre verde50

  // Secundárias
  static const petroleo = Color(0xFF0F2A36); // marca, mensagens do usuário, painéis
  static const menta = Color(0xFF7FD3C3); // destaque sobre fundos escuros
  static const sobrePetroleo = Color(0xFFB9CCD3);
  static const sobrePetroleoTexto = Color(0xFFDCE6EA);
  static const sobrePetroleoApoio = Color(0xFFB9CCD3);

  // Neutros
  static const tinta = Color(0xFF14212B); // 900: texto (16,8:1)
  static const corpo = Color(0xFF2B3943); // texto corrido
  static const apoio = Color(0xFF4F5D68); // 600: texto secundário (6,6:1)
  static const apoioClaro = Color(0xFF6A7782); // 500: ícones e placeholder
  static const bordaCampo = Color(0xFFC9D1D5); // 300: campos e botões contornados
  static const linha = Color(0xFFE2E7E9); // 200: bordas de cartões e divisórias
  static const trilho = Color(0xFFEBEEF0); // 100: desativado, esqueleto
  static const fundo = Color(0xFFF7F8F8); // 25: fundo das telas
  static const fundoSuave = Color(0xFFF1F4F4);

  // Estados
  static const sucesso = Color(0xFF1E7A4C);
  static const sucessoFundo = Color(0xFFE8F5EE);
  static const sucessoLinha = Color(0xFFBFE0CC);
  static const sucessoTexto = Color(0xFF14512F);
  static const alerta = Color(0xFFA35A00);
  static const alertaFundo = Color(0xFFFDF3E2);
  static const alertaLinha = Color(0xFFF2DDB8);
  static const alertaTexto = Color(0xFF5C3300);
  static const alertaRotulo = Color(0xFF8A4B05);
  static const erro = Color(0xFFC0362C);
  static const erroFundo = Color(0xFFFCEDEB);
  static const erroLinha = Color(0xFFF1C9C4);
  static const erroTitulo = Color(0xFF7A2018);
  static const erroTexto = Color(0xFF7A2018);
  static const erroForte = Color(0xFF9E2B22);
  static const info = Color(0xFF2560A8);
  static const infoFundo = Color(0xFFEAF1FA);
  static const infoLinha = Color(0xFFC8DAF0);
  static const infoTexto = Color(0xFF173F6E);
  static const infoRotulo = Color(0xFF1F4F8A);

  // Níveis de atenção (1, 2, 3)
  static const nivelFundo = [verde50, infoFundo, Color(0xFFF1EEF8)];
  static const nivelTexto = [acaoEscuro, infoRotulo, Color(0xFF4B3B8C)];

  // Botão do Google (diretrizes da marca, tema claro)
  static const googleBorda = Color(0xFF747775);
  static const googleTexto = Color(0xFF1F1F1F);
}

/// Cantos: 6 selos · 8 chips · 10 botões e campos · 14 cartões · 16 modais.
abstract final class CuidaRaio {
  static const selo = 6.0;
  static const chip = 8.0;
  static const botao = 10.0;
  static const campo = 10.0;
  static const cartao = 14.0;
  static const modal = 16.0;
  static const formaBotao = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(botao)));
  static const formaChip = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(chip)));
}

/// Tokens que mudam com as preferências de acessibilidade
/// (alto contraste, leitura facilitada e movimento reduzido).
@immutable
class CuidaTema extends ThemeExtension<CuidaTema> {
  const CuidaTema({this.altoContraste = false, this.leituraFacil = false, this.movimentoReduzido = false});

  final bool altoContraste;
  final bool leituraFacil;
  final bool movimentoReduzido;

  /// Desligado nos testes, onde não há rede para baixar as fontes.
  static bool usarGoogleFonts = true;

  Color get texto => CuidaCores.tinta;
  Color get corpo => altoContraste ? CuidaCores.tinta : CuidaCores.corpo;
  Color get mut => altoContraste ? CuidaCores.corpo : CuidaCores.apoio;
  Color get linha => altoContraste ? CuidaCores.tinta : CuidaCores.linha;
  Color get borda => altoContraste ? CuidaCores.tinta : CuidaCores.bordaCampo;
  Color get bordaBotao => altoContraste ? CuidaCores.tinta : CuidaCores.bordaCampo;
  double get larguraBorda => altoContraste ? 2 : 1;
  Color get tint => altoContraste ? Colors.white : CuidaCores.verde50;

  Duration duracao(Duration d) => movimentoReduzido ? Duration.zero : d;

  /// Bordas finas no lugar de sombras: cartões não têm sombra.
  List<BoxShadow> sombra() => const [];

  /// Sombra só no que flutua (menus e modais).
  List<BoxShadow> get sombraFlutuante =>
      altoContraste ? const [] : const [BoxShadow(color: Color(0x330F2A36), blurRadius: 40, offset: Offset(0, 16))];

  /// Contorno de cartões e superfícies brancas.
  BoxBorder get contornoCartao => Border.all(color: linha, width: altoContraste ? 1.5 : 1);

  /// Texto de interface e leitura (Manrope).
  TextStyle sans(
    double tamanho, {
    double? lh,
    FontWeight peso = FontWeight.w500,
    Color? cor,
    TextDecoration? decoracao,
    FontStyle? estilo,
  }) {
    final base = TextStyle(
      fontSize: tamanho,
      height: lh == null ? null : lh / tamanho,
      fontWeight: peso,
      fontStyle: estilo,
      color: cor ?? texto,
      letterSpacing: leituraFacil ? tamanho * 0.01 : 0,
      decoration: decoracao,
      decorationColor: cor ?? texto,
    );
    return _fonte(base);
  }

  /// Títulos: Manrope 800 com espaçamento levemente apertado (-0,02 em).
  TextStyle titulo(
    double tamanho, {
    double? lh,
    FontWeight peso = FontWeight.w800,
    Color? cor,
    double tracking = -0.02,
  }) {
    final base = TextStyle(
      fontSize: tamanho,
      height: lh == null ? null : lh / tamanho,
      fontWeight: peso,
      color: cor ?? CuidaCores.tinta,
      letterSpacing: tamanho * (leituraFacil ? 0.01 : tracking),
    );
    return _fonte(base);
  }

  /// Rótulo de seção em caixa alta: 12/16, 800, +0,04 em.
  TextStyle legenda({Color? cor, double tamanho = 12}) {
    final base = TextStyle(
      fontSize: tamanho,
      height: 16 / 12,
      fontWeight: FontWeight.w800,
      color: cor ?? mut,
      letterSpacing: tamanho * 0.04,
    );
    return _fonte(base);
  }

  TextStyle _fonte(TextStyle base) {
    if (!usarGoogleFonts) return base;
    try {
      return GoogleFonts.getFont(leituraFacil ? 'Atkinson Hyperlegible' : 'Manrope', textStyle: base);
    } catch (_) {
      return base;
    }
  }

  /// Roboto Medium, exigida pelas diretrizes do botão "Continuar com o Google".
  static TextStyle roboto(TextStyle base) {
    if (!usarGoogleFonts) return base;
    try {
      return GoogleFonts.roboto(textStyle: base);
    } catch (_) {
      return base;
    }
  }

  @override
  CuidaTema copyWith({bool? altoContraste, bool? leituraFacil, bool? movimentoReduzido}) {
    return CuidaTema(
      altoContraste: altoContraste ?? this.altoContraste,
      leituraFacil: leituraFacil ?? this.leituraFacil,
      movimentoReduzido: movimentoReduzido ?? this.movimentoReduzido,
    );
  }

  @override
  CuidaTema lerp(CuidaTema? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension CuidaContexto on BuildContext {
  CuidaTema get tema => Theme.of(this).extension<CuidaTema>() ?? const CuidaTema();
}

class _SemTransicao extends PageTransitionsBuilder {
  const _SemTransicao();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

ThemeData construirTema(CuidaTema cuida) {
  final esquema = ColorScheme.fromSeed(
    seedColor: CuidaCores.acao,
    primary: CuidaCores.acao,
    onPrimary: Colors.white,
    secondary: CuidaCores.petroleo,
    error: CuidaCores.erro,
    surface: CuidaCores.fundo,
    onSurface: cuida.texto,
  );
  final transicoes = cuida.movimentoReduzido
      ? const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SemTransicao(),
            TargetPlatform.iOS: _SemTransicao(),
            TargetPlatform.windows: _SemTransicao(),
            TargetPlatform.macOS: _SemTransicao(),
            TargetPlatform.linux: _SemTransicao(),
          },
        )
      : const PageTransitionsTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: CuidaCores.fundo,
    canvasColor: CuidaCores.fundo,
    textTheme: Typography.blackMountainView.apply(bodyColor: cuida.texto, displayColor: CuidaCores.tinta),
    pageTransitionsTheme: transicoes,
    splashFactory: cuida.movimentoReduzido ? NoSplash.splashFactory : InkRipple.splashFactory,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: CuidaCores.acao,
      selectionColor: CuidaCores.verde100,
      selectionHandleColor: CuidaCores.acao,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? CuidaCores.acao : Colors.white,
      ),
      side: BorderSide(color: cuida.borda, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CuidaCores.tinta,
      contentTextStyle: cuida.sans(14, peso: FontWeight.w600, cor: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CuidaRaio.botao)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(CuidaRaio.modal))),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(CuidaRaio.modal))),
    ),
    extensions: [cuida],
  );
}
