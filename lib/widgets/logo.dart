import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/cuida_tema.dart';

/// Símbolo: balão (diálogo), rede (serviços que se comunicam) e sinal + (cuidado).
String _simboloSvg({required String balao, required String traco, required String cruz}) => '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path d="M12 6h24a8 8 0 0 1 8 8v14a8 8 0 0 1-8 8H23l-9 7v-7h-2a8 8 0 0 1-8-8V14a8 8 0 0 1 8-8z" fill="$balao"/>
  <path d="M15 25 24 16l9 9M15 25h18" fill="none" stroke="$traco" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="15" cy="25" r="3.6" fill="$traco"/><circle cx="33" cy="25" r="3.6" fill="$traco"/>
  <circle cx="24" cy="15" r="6.4" fill="$balao"/>
  <path d="M24 11v8M20 15h8" fill="none" stroke="$cruz" stroke-width="3.4" stroke-linecap="round"/>
</svg>''';

final _simboloPadrao = _simboloSvg(balao: '#123B50', traco: '#FFFFFF', cruz: '#20A89A');
final _simboloInvertido = _simboloSvg(balao: '#DDF4EE', traco: '#123B50', cruz: '#137A70');

class CuidaSimbolo extends StatelessWidget {
  const CuidaSimbolo({super.key, this.tamanho = 34, this.invertido = false});

  final double tamanho;
  final bool invertido;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      invertido ? _simboloInvertido : _simboloPadrao,
      width: tamanho,
      height: tamanho,
      excludeFromSemantics: true,
    );
  }
}

/// Logotipo "CuidaIA": "Cuida" em serifa e "IA" em sans-serif verde-água.
class CuidaMarca extends StatelessWidget {
  const CuidaMarca({super.key, this.tamanho = 25, this.sobreAzul = false});

  final double tamanho;
  final bool sobreAzul;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      label: 'CuidaIA',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: 'Cuida',
          style: t.serif(tamanho,
              peso: FontWeight.w600, tracking: -0.01, cor: sobreAzul ? Colors.white : CuidaCores.azul),
          children: [
            TextSpan(
              text: 'IA',
              style: t.sans(tamanho * 0.84,
                  peso: FontWeight.w600, cor: sobreAzul ? CuidaCores.verdeLogo : CuidaCores.verde700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grafo decorativo (nós e conexões) usado no Login e no destaque da página inicial.
class RedeDecorativa extends StatelessWidget {
  const RedeDecorativa.login({super.key}) : _compacta = false;
  const RedeDecorativa.destaque({super.key}) : _compacta = true;

  final bool _compacta;

  static const _login = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 230 200">
  <g fill="none" stroke="#20A89A" stroke-width="1.1" opacity="0.6"><path d="M30 170 92 98l64 40 52-96"/><path d="M92 98 122 34M156 138l46 34M30 170l126-32"/></g>
  <g fill="#20A89A"><circle cx="30" cy="170" r="3.2"/><circle cx="92" cy="98" r="4.4"/><circle cx="156" cy="138" r="3.4"/><circle cx="208" cy="42" r="3"/><circle cx="122" cy="34" r="2.6"/><circle cx="202" cy="172" r="2.6"/></g>
</svg>''';

  static const _destaque = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 150">
  <g fill="none" stroke="#20A89A" stroke-width="1.1" opacity="0.55"><path d="M24 128 80 70l52 30 48-74"/><path d="M80 70 108 20M132 100l40 34"/></g>
  <g fill="#20A89A" opacity="0.9"><circle cx="24" cy="128" r="3"/><circle cx="80" cy="70" r="4"/><circle cx="132" cy="100" r="3"/><circle cx="180" cy="26" r="3"/><circle cx="108" cy="20" r="2.4"/><circle cx="172" cy="134" r="2.4"/></g>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(
        _compacta ? _destaque : _login,
        width: _compacta ? 200 : 230,
        height: _compacta ? 150 : 200,
      ),
    );
  }
}
