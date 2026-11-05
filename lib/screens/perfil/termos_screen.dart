import 'package:flutter/material.dart';

import '../../data/conteudos.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';
import 'privacidade_screen.dart';

class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  static const _secoes = [
    SecaoArtigo('O que é o CuidaIA', [
      'Um aplicativo educativo e de orientação. Ele explica, em linguagem simples, como funcionam o SUS e a Rede de Atenção à Saúde, e ajuda você a identificar qual tipo de serviço procurar — UBS, UPA, SAMU ou CAPS — a partir da situação que você mesmo descreve.',
      'O CuidaIA não é um aplicativo oficial do Ministério da Saúde nem do SUS.',
    ]),
    SecaoArtigo('O que o app não faz', [
      'A orientação indica um tipo de serviço, nunca o que você tem. Por isso, o app:',
    ], [
      'Não faz diagnósticos nem avalia a gravidade de sintomas',
      'Não indica tratamentos nem medicamentos',
      'Não agenda consultas nem exames',
      'Não substitui profissionais de saúde',
    ]),
    SecaoArtigo('Sobre o assistente de IA', [
      'As respostas são geradas por inteligência artificial a partir de materiais oficiais e podem conter erros ou ficar desatualizadas. Sempre indicamos a fonte — confira antes de tomar decisões.',
    ]),
    SecaoArtigo('Sua conta', [
      'Você é responsável por manter sua senha em segurança. Se perceber algum acesso estranho, altere a senha e fale com o suporte.',
    ]),
    SecaoArtigo('Uso adequado', [
      'Não use o app para enviar conteúdo ofensivo, tentar acessar dados de outras pessoas ou prejudicar o funcionamento do serviço.',
    ]),
    SecaoArtigo('Mudanças e contato', [
      'Se os termos mudarem, avisaremos no app antes de as mudanças valerem. Dúvidas: [E-MAIL DE CONTATO].',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return TelaInterna(
      titulo: 'Termos de uso',
      espaco: 28,
      children: [
        Text('Última atualização: 4 de novembro de 2026', style: t.sans(13.5, cor: t.mut)),
        Semantics(
          container: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(color: CuidaCores.azul, borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Em caso de emergência', style: t.sans(14, peso: FontWeight.w600, cor: CuidaCores.verdeClaro)),
                const SizedBox(height: 6),
                Text(
                  'Não use o app. Ligue 192 (SAMU) ou procure o pronto-socorro mais próximo.',
                  style: t.serif(19, lh: 26, peso: FontWeight.w400, cor: Colors.white),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < _secoes.length; i++) SecaoTexto(secao: _secoes[i], numero: '${i + 1}'),
        BotaoSecundario(
          'Ler a Política de privacidade',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacidadeScreen())),
        ),
      ],
    );
  }
}
