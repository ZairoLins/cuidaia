import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AppScope.of(context);
    LinhaInterruptor item(String chave, String titulo, String descricao) => LinhaInterruptor(
          titulo: titulo,
          descricao: descricao,
          valor: estado.notificacao(chave),
          onChanged: (v) => estado.definirNotificacao(chave, v),
        );

    return TelaInterna(
      titulo: 'Notificações',
      subtitulo: 'Escolha o que receber. Você pode mudar quando quiser.',
      espaco: 28,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('No celular'),
            const SizedBox(height: 10),
            Cartao(
              child: ListaSeparada(children: [
                item('conteudos', 'Novos conteúdos educativos', 'Quando publicarmos artigos sobre o SUS'),
                item('leitura', 'Continuar leitura', 'Lembrete de artigos que você começou'),
                item('novidades', 'Novidades do CuidaIA', 'Novos recursos e melhorias'),
              ]),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('Por e-mail'),
            const SizedBox(height: 10),
            Cartao(
              child: ListaSeparada(children: [
                item('resumo', 'Resumo mensal', 'Os conteúdos mais lidos do mês'),
              ]),
            ),
          ],
        ),
        const NotaApoio(
          texto:
              'As notificações nunca mostram dados pessoais nem o conteúdo das conversas na tela bloqueada. Avisos de segurança da conta são sempre enviados.',
        ),
      ],
    );
  }
}
