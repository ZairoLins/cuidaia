import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/cuida_tema.dart';

/// Símbolo: balão (diálogo) em petróleo, rede (serviços que se comunicam) em
/// branco e sinal + (cuidado) em menta.
const _simboloSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path d="M12 6h24a8 8 0 0 1 8 8v14a8 8 0 0 1-8 8H23l-9 7v-7h-2a8 8 0 0 1-8-8V14a8 8 0 0 1 8-8z" fill="#0F2A36"/>
  <path d="M15 25 24 16l9 9M15 25h18" fill="none" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="15" cy="25" r="3.6" fill="#FFFFFF"/><circle cx="33" cy="25" r="3.6" fill="#FFFFFF"/>
  <circle cx="24" cy="15" r="6.4" fill="#0F2A36"/>
  <path d="M24 11v8M20 15h8" fill="none" stroke="#7FD3C3" stroke-width="3.4" stroke-linecap="round"/>
</svg>''';

class CuidaSimbolo extends StatelessWidget {
  const CuidaSimbolo({super.key, this.tamanho = 30});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_simboloSvg, width: tamanho, height: tamanho, excludeFromSemantics: true);
  }
}

/// Logotipo "CuidaIA": Manrope 800, "Cuida" em petróleo e "IA" no verde de ação.
class CuidaMarca extends StatelessWidget {
  const CuidaMarca({super.key, this.tamanho = 19, this.sobreEscuro = false});

  final double tamanho;
  final bool sobreEscuro;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      label: 'CuidaIA',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: 'Cuida',
          style: t.titulo(tamanho, cor: sobreEscuro ? Colors.white : CuidaCores.petroleo),
          children: [
            TextSpan(
              text: 'IA',
              style: t.titulo(tamanho, cor: sobreEscuro ? CuidaCores.menta : CuidaCores.acao),
            ),
          ],
        ),
      ),
    );
  }
}

/// Símbolo e nome lado a lado, como no topo do login.
class CuidaLogo extends StatelessWidget {
  const CuidaLogo({super.key, this.simbolo = 30, this.nome = 19});

  final double simbolo;
  final double nome;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CuidaSimbolo(tamanho: simbolo),
        const SizedBox(width: 10),
        CuidaMarca(tamanho: nome),
      ],
    );
  }
}
