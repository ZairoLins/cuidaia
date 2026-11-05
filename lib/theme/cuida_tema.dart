import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta da identidade visual CuidaIA.
abstract final class CuidaCores {
  static const azul = Color(0xFF123B50);
  static const verde700 = Color(0xFF137A70);
  static const verde = Color(0xFF20A89A);
  static const verdeSuave = Color(0xFFDDF4EE);
  static const verdeSelecao = Color(0xFFEEF8F5);
  static const verdeTexto = Color(0xFF0E5C55);
  static const verdeClaro = Color(0xFFA9E6DD);
  static const verdeLogo = Color(0xFF7FD9CD);
  static const grafite = Color(0xFF263746);
  static const fundo = Color(0xFFF4F8FA);
  static const apoio = Color(0xFF4D6070);
  static const linha = Color(0xFFE1E8EC);
  static const borda = Color(0xFFCBD6DC);
  static const bordaBotao = Color(0xFFB9C8D1);
  static const placeholder = Color(0xFF5E7180);
  static const desativado = Color(0xFF9DB3BF);
  static const trilho = Color(0xFFE8EEF1);
  static const tintaEscura = Color(0xFF0B2533);
  static const sobreAzul = Color(0xFFC8D8DF);
  static const sobreAzulTexto = Color(0xFFD3E0E6);
  static const sobreAzulApoio = Color(0xFFAFC3CD);
  static const erro = Color(0xFFB42318);
  static const erroFundo = Color(0xFFFDF1F0);
  static const erroTitulo = Color(0xFF7A1A12);
  static const erroTexto = Color(0xFF5C2620);
  static const erroLinha = Color(0xFFF3C9C4);
  static const laranja = Color(0xFFC2740A);
  static const altoContrasteTexto = Color(0xFF0B1A24);
  static const altoContrasteApoio = Color(0xFF13222D);
}

/// Tokens que mudam com as preferências de acessibilidade
/// (alto contraste, leitura facilitada e movimento reduzido).
@immutable
class CuidaTema extends ThemeExtension<CuidaTema> {
  const CuidaTema({
    this.altoContraste = false,
    this.leituraFacil = false,
    this.movimentoReduzido = false,
  });

  final bool altoContraste;
  final bool leituraFacil;
  final bool movimentoReduzido;

  /// Desligado nos testes, onde não há rede para baixar as fontes.
  static bool usarGoogleFonts = true;

  Color get texto => altoContraste ? CuidaCores.altoContrasteTexto : CuidaCores.grafite;
  Color get mut => altoContraste ? CuidaCores.altoContrasteApoio : CuidaCores.apoio;
  Color get linha => altoContraste ? CuidaCores.grafite : CuidaCores.linha;
  Color get borda => altoContraste ? CuidaCores.grafite : CuidaCores.borda;
  Color get bordaBotao => altoContraste ? CuidaCores.grafite : CuidaCores.bordaBotao;
  double get larguraBorda => altoContraste ? 2 : 1;
  Color get tint => altoContraste ? Colors.white : CuidaCores.verdeSuave;

  Duration duracao(Duration d) => movimentoReduzido ? Duration.zero : d;

  /// Sombra suave dos cartões; no alto contraste vira contorno.
  List<BoxShadow> sombra({double blur = 28, double y = 10, double spread = -14, double alpha = 0.22}) {
    if (altoContraste) return const [];
    return [
      BoxShadow(color: CuidaCores.azul.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
      BoxShadow(
        color: CuidaCores.azul.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: spread,
        offset: Offset(0, y),
      ),
    ];
  }

  BoxBorder? get contornoCartao =>
      altoContraste ? Border.all(color: CuidaCores.grafite, width: 1.5) : null;

  /// Texto de interface (Geist).
  TextStyle sans(
    double tamanho, {
    double? lh,
    FontWeight peso = FontWeight.w400,
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
      letterSpacing: leituraFacil ? tamanho * 0.01 : null,
      decoration: decoracao,
      decorationColor: cor ?? texto,
    );
    return _fonte(leituraFacil ? 'Atkinson Hyperlegible' : 'Geist', base);
  }

  /// Títulos editoriais (Newsreader).
  TextStyle serif(
    double tamanho, {
    double? lh,
    FontWeight peso = FontWeight.w500,
    Color? cor,
    double tracking = 0,
  }) {
    final base = TextStyle(
      fontSize: tamanho,
      height: lh == null ? null : lh / tamanho,
      fontWeight: peso,
      color: cor ?? CuidaCores.azul,
      letterSpacing: leituraFacil ? tamanho * 0.01 : tamanho * tracking,
    );
    return _fonte(leituraFacil ? 'Atkinson Hyperlegible' : 'Newsreader', base);
  }

  static TextStyle _fonte(String familia, TextStyle base) {
    if (!usarGoogleFonts) return base;
    try {
      return GoogleFonts.getFont(familia, textStyle: base);
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
  ) =>
      child;
}

ThemeData construirTema(CuidaTema cuida) {
  final esquema = ColorScheme.fromSeed(
    seedColor: CuidaCores.verde700,
    primary: CuidaCores.verde700,
    onPrimary: Colors.white,
    secondary: CuidaCores.azul,
    error: CuidaCores.erro,
    surface: CuidaCores.fundo,
    onSurface: cuida.texto,
  );
  final transicoes = cuida.movimentoReduzido
      ? const PageTransitionsTheme(builders: {
          TargetPlatform.android: _SemTransicao(),
          TargetPlatform.iOS: _SemTransicao(),
          TargetPlatform.windows: _SemTransicao(),
          TargetPlatform.macOS: _SemTransicao(),
          TargetPlatform.linux: _SemTransicao(),
        })
      : const PageTransitionsTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: CuidaCores.fundo,
    canvasColor: CuidaCores.fundo,
    textTheme: Typography.blackMountainView.apply(bodyColor: cuida.texto, displayColor: CuidaCores.azul),
    pageTransitionsTheme: transicoes,
    splashFactory: cuida.movimentoReduzido ? NoSplash.splashFactory : InkRipple.splashFactory,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: CuidaCores.verde700,
      selectionColor: CuidaCores.verde.withValues(alpha: 0.3),
      selectionHandleColor: CuidaCores.verde700,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? CuidaCores.verde700 : Colors.white,
      ),
      side: BorderSide(color: cuida.borda, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CuidaCores.azul,
      contentTextStyle: cuida.sans(14.5, cor: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    extensions: [cuida],
  );
}
