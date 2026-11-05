import 'package:flutter/material.dart';

import '../../services/voz.dart';
import '../../state/app_state.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';

class AcessibilidadeScreen extends StatelessWidget {
  const AcessibilidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final estado = AppScope.of(context);
    final a = estado.a11y;
    void mudar(PreferenciasA11y novas) => estado.atualizarA11y(novas);

    return TelaInterna(
      titulo: 'Acessibilidade',
      subtitulo: 'As mudanças valem na hora, em todas as telas, e ficam salvas neste aparelho.',
      espaco: 32,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('Tamanho do texto', forte: true),
            const SizedBox(height: 12),
            _SeletorTamanho(atual: a.texto, onChanged: (v) => mudar(a.copyWith(texto: v))),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('Pré-visualização', forte: true),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Cartao(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Atenção Primária · 5 min', style: t.sans(13, peso: FontWeight.w500, cor: t.mut)),
                    const SizedBox(height: 8),
                    Text('A porta de entrada do SUS', style: t.serif(22, lh: 27.5)),
                    const SizedBox(height: 8),
                    Text(
                      'A Unidade Básica de Saúde é o lugar de referência para consultas, vacinas e acompanhamento.',
                      style: t.sans(16, lh: 25.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('Visão, leitura e movimento', forte: true),
            const SizedBox(height: 12),
            Cartao(
              child: ListaSeparada(
                children: [
                  LinhaInterruptor(
                    titulo: 'Alto contraste',
                    descricao: 'Textos mais escuros e contornos mais fortes',
                    valor: a.contraste,
                    onChanged: (v) => mudar(a.copyWith(contraste: v)),
                  ),
                  LinhaInterruptor(
                    titulo: 'Fonte de leitura facilitada',
                    descricao: 'Letras mais distintas entre si (Atkinson Hyperlegible)',
                    valor: a.leitura,
                    onChanged: (v) => mudar(a.copyWith(leitura: v)),
                  ),
                  LinhaInterruptor(
                    titulo: 'Reduzir movimento',
                    descricao: 'Desliga animações e transições',
                    valor: a.movimento,
                    onChanged: (v) => mudar(a.copyWith(movimento: v)),
                  ),
                  LinhaInterruptor(
                    titulo: 'Ler respostas em voz alta',
                    descricao: 'O assistente lê cada resposta do chat',
                    valor: a.voz,
                    onChanged: (v) => mudar(a.copyWith(voz: v)),
                  ),
                ],
              ),
            ),
            if (a.voz) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: BotaoCompacto(
                  'Testar a voz',
                  icone: Icons.volume_up_outlined,
                  preenchido: true,
                  onPressed: () => Voz.instancia.falar(
                    'teste',
                    'Olá! Esta é a voz que vai ler as respostas do assistente CuidaIA.',
                  ),
                ),
              ),
            ],
          ],
        ),
        const NotaApoio(
          icone: Icons.info_outline_rounded,
          tamanho: 13.5,
          texto: 'O CuidaIA também segue o leitor de tela e a opção de reduzir movimento configurados no seu celular.',
        ),
        BotaoSecundario('Restaurar padrão', altura: 52, onPressed: () => mudar(const PreferenciasA11y())),
      ],
    );
  }
}

/// Controle segmentado com amostra "Aa" em cada tamanho.
class _SeletorTamanho extends StatelessWidget {
  const _SeletorTamanho({required this.atual, required this.onChanged});

  final TamanhoTexto atual;
  final ValueChanged<TamanhoTexto> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    const amostras = {TamanhoTexto.padrao: 18.0, TamanhoTexto.grande: 23.0, TamanhoTexto.muito: 28.0};
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CuidaCores.trilho,
        borderRadius: BorderRadius.circular(18),
        border: t.altoContraste ? Border.all(color: CuidaCores.grafite, width: 1.5) : null,
      ),
      // As amostras já mostram o tamanho; evita dupla ampliação aqui.
      child: MediaQuery.withNoTextScaling(
        child: Row(
          children: [
            for (final tam in TamanhoTexto.values) ...[
              if (tam != TamanhoTexto.padrao) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: tam == atual,
                  button: true,
                  label: 'Tamanho do texto: ${tam.rotulo}',
                  onTap: () => onChanged(tam),
                  excludeSemantics: true,
                  child: Material(
                    color: tam == atual ? Colors.white : Colors.transparent,
                    elevation: tam == atual && !t.altoContraste ? 1 : 0,
                    shadowColor: CuidaCores.azul.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: tam == atual && t.altoContraste
                          ? const BorderSide(color: CuidaCores.grafite, width: 1.5)
                          : BorderSide.none,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onChanged(tam),
                      child: SizedBox(
                        height: 76,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Aa', style: t.serif(amostras[tam]!, lh: amostras[tam]!)),
                            const SizedBox(height: 6),
                            Text(
                              tam.rotulo,
                              textAlign: TextAlign.center,
                              style: t.sans(12.5,
                                  lh: 16,
                                  peso: tam == atual ? FontWeight.w700 : FontWeight.w500,
                                  cor: CuidaCores.azul),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
