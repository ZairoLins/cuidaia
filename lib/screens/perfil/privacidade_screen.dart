import 'package:flutter/material.dart';

import '../../data/conteudos.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';
import 'meus_dados_screen.dart';

class PrivacidadeScreen extends StatelessWidget {
  const PrivacidadeScreen({super.key});

  static const _resumo = [
    'Pedimos só o necessário: nome, e-mail e senha.',
    'Não pedimos informações sobre a sua saúde.',
    'Não vendemos nem usamos seus dados para publicidade.',
    'Você pode baixar ou apagar seus dados quando quiser.',
  ];

  static const _secoes = [
    SecaoArtigo(
      'Quais dados usamos',
      ['Usamos apenas o que o app precisa para funcionar:'],
      [
        'Dados da conta: nome, e-mail, senha (guardada de forma criptografada) e, se você quiser, uma foto de perfil. Se você entrar com o Google, recebemos dele apenas o seu nome e o seu e-mail, e não há senha guardada no CuidaIA',
        'Preferências: acessibilidade, notificações e conteúdos salvos, guardados só no seu aparelho',
        'Conversas com o assistente: ficam só no seu aparelho e são apagadas quando você sai da conta. Não guardamos conversas nos nossos servidores',
        'Localização: o CuidaIA não usa. O botão "Ver unidades perto de mim" abre o app de mapas do seu celular, que usa a sua localização pelas regras dele',
      ],
    ),
    SecaoArtigo('Um cuidado nas conversas', [
      'Evite escrever no chat dados pessoais, como CPF, endereço ou detalhes do seu estado de saúde. O assistente não precisa deles para explicar como o SUS funciona.',
      'Usamos o plano gratuito do Gemini, e pelas regras desse plano o Google pode usar o texto das perguntas, inclusive com revisão humana, para melhorar os próprios serviços. As perguntas são enviadas sem o seu nome e sem o seu e-mail.',
    ]),
    SecaoArtigo('Para que usamos', [
      'Para criar e proteger sua conta, responder às suas perguntas, lembrar suas preferências e melhorar os conteúdos com dados agregados, sem identificar você.',
      'O tratamento se baseia no seu consentimento, que pode ser revogado a qualquer momento.',
    ]),
    SecaoArtigo('Com quem compartilhamos', [
      'As perguntas são processadas pelo Gemini, a inteligência artificial do Google, para gerar as respostas. A conta e o perfil ficam no Firebase, serviço de hospedagem do Google. Não compartilhamos seus dados com outras empresas.',
    ]),
    SecaoArtigo(
      'Seus direitos',
      ['Pela LGPD, você pode, entre outros direitos:'],
      [
        'Saber quais dados temos e acessá-los',
        'Corrigir dados incompletos ou errados',
        'Receber uma cópia (portabilidade)',
        'Pedir a eliminação dos seus dados',
        'Saber com quem seus dados são compartilhados',
        'Revogar o seu consentimento',
      ],
    ),
    SecaoArtigo('Fale com a gente', [
      'Encarregado pelo tratamento de dados: Zairo Lins Ribeiro Cunha — zairolins15@gmail.com.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return TelaInterna(
      titulo: 'Política de privacidade',
      espaco: 32,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Última atualização: 8 de novembro de 2026', style: t.sans(13.5, cor: t.mut)),
            const SizedBox(height: 14),
            Text(
              'Explicamos, em linguagem simples, quais dados o CuidaIA usa e como você controla cada um deles, de acordo com a Lei Geral de Proteção de Dados (LGPD).',
              style: t.sans(16.5, lh: 26),
            ),
          ],
        ),
        Cartao(
          raio: 22,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Em resumo', style: t.titulo(21))),
              const SizedBox(height: 8),
              ListaSeparada(
                children: [
                  for (final r in _resumo)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded, size: 18, color: CuidaCores.acao),
                          const SizedBox(width: 12),
                          Expanded(child: Text(r, style: t.sans(15, lh: 22))),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        for (final s in _secoes) SecaoTexto(secao: s),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BotaoPrimario(
              'Gerenciar meus dados',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MeusDadosScreen())),
            ),
            const SizedBox(height: 16),
            const LinkReferencia(referencia: refLgpd),
          ],
        ),
      ],
    );
  }
}

/// Seção de texto corrido: título em serifa, parágrafos e lista opcional.
class SecaoTexto extends StatelessWidget {
  const SecaoTexto({super.key, required this.secao, this.numero});

  final SecaoArtigo secao;
  final String? numero;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                if (numero != null)
                  TextSpan(
                    text: '$numero   ',
                    style: t.titulo(17, cor: CuidaCores.acao),
                  ),
                TextSpan(text: secao.titulo),
              ],
            ),
            style: t.titulo(22, lh: 27),
          ),
        ),
        for (final p in secao.paragrafos) ...[const SizedBox(height: 12), Text(p, style: t.sans(16, lh: 26))],
        if (secao.itens.isNotEmpty) ...[const SizedBox(height: 12), ListaMarcadores(itens: secao.itens)],
      ],
    );
  }
}
