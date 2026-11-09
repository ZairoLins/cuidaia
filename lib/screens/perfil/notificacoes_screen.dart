import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/widgets.dart';

class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AppScope.of(context);

    Future<void> alternar(String chave, bool valor) async {
      final ok = await estado.definirNotificacao(chave, valor);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('As notificações estão bloqueadas para o CuidaIA. Libere nas configurações do celular.'),
          ),
        );
      }
    }

    LinhaInterruptor item(String chave, String titulo, String descricao) => LinhaInterruptor(
      titulo: titulo,
      descricao: descricao,
      valor: estado.notificacao(chave),
      onChanged: (v) => alternar(chave, v),
    );

    return TelaInterna(
      titulo: 'Notificações',
      subtitulo: 'Escolha o que receber. Você pode mudar quando quiser.',
      espaco: 28,
      children: [
        if (!estado.notificacoesDisponiveis)
          const NotaApoio(
            texto: 'Os lembretes funcionam no app para celular Android. Nesta versão, eles não são enviados.',
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RotuloSecao('No celular'),
              const SizedBox(height: 10),
              Cartao(
                child: ListaSeparada(
                  children: [
                    item('dica', 'Dica da semana', 'Toda segunda-feira, uma dica curta sobre como usar o SUS'),
                    item('leitura', 'Continuar leitura', 'No dia seguinte, se você não terminar um artigo'),
                  ],
                ),
              ),
            ],
          ),
        const NotaApoio(
          texto: 'Os lembretes são criados no próprio celular, sem passar por servidores. Eles nunca mostram dados pessoais nem o conteúdo das conversas.',
        ),
      ],
    );
  }
}
