import 'package:flutter/material.dart';

import '../data/conteudos.dart';
import '../services/links.dart';
import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'artigo_screen.dart';
import 'home_shell.dart';
import 'perfil/notificacoes_screen.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final estado = AppScope.of(context);
    final shell = HomeShell.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 16, 0),
            child: Row(
              children: [
                const Expanded(child: CuidaMarca(tamanho: 22)),
                IconButton(
                  tooltip: 'Notificações',
                  color: CuidaCores.azul,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded, size: 24),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(estado.usuario.primeiroNome.isEmpty ? 'Olá!' : 'Olá, ${estado.usuario.primeiroNome}', style: t.sans(15, peso: FontWeight.w500, cor: t.mut)),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  child: Text('Como podemos ajudar você hoje?', style: t.serif(34, lh: 39, tracking: -0.015)),
                ),
                const SizedBox(height: 40),
                _Destaque(onConversar: () => shell.abrirChat()),
                const SizedBox(height: 24),
                Cartao(
                  raio: 22,
                  sombra: true,
                  onTap: () => shell.abrirChat(orientacao: true),
                  padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.tint,
                          shape: BoxShape.circle,
                          border: t.altoContraste ? Border.all(color: CuidaCores.grafite, width: 1.5) : null,
                        ),
                        child: const Icon(Icons.location_on_outlined, size: 22, color: CuidaCores.azul),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Onde procurar atendimento?',
                                style: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul)),
                            const SizedBox(height: 2),
                            Text(
                              'UBS, UPA ou SAMU: responda uma pergunta e veja o serviço indicado',
                              style: t.sans(13.5, lh: 19, cor: t.mut),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right_rounded, color: t.mut),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => ligar(context, '192'),
                    style: TextButton.styleFrom(
                      foregroundColor: CuidaCores.erro,
                      minimumSize: const Size(0, 44),
                      textStyle: t.sans(14, peso: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 17),
                    label: const Text('Emergência? Ligue 192 (SAMU)'),
                  ),
                ),
                const SizedBox(height: 40),
                const RotuloSecao('Continue lendo', forte: true),
                const SizedBox(height: 14),
                Cartao(
                  onTap: () => abrirArtigo(context, 'primaria'),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Atenção Primária', style: t.sans(13, cor: t.mut)),
                                const SizedBox(height: 4),
                                Text('A porta de entrada do SUS', style: t.serif(20, lh: 25)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.chevron_right_rounded, color: t.mut),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Progresso de leitura',
                              value: '60%',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: const LinearProgressIndicator(
                                  value: 0.6,
                                  minHeight: 4,
                                  color: CuidaCores.verde700,
                                  backgroundColor: CuidaCores.linha,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('2 min restantes', style: t.sans(13, cor: t.mut)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text('Rede de Atenção à Saúde', style: t.serif(24, lh: 29)),
                      ),
                    ),
                    BotaoLink('Ver tudo', onPressed: () => shell.irPara(Aba.aprenda)),
                  ],
                ),
                const SizedBox(height: 14),
                Cartao(
                  child: ListaSeparada(
                    children: [
                      for (final n in niveisAtencao)
                        LinhaNavegacao(
                          titulo: n.titulo,
                          descricao: n.resumo,
                          tituloEstilo: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          inicio: SizedBox(
                            width: 28,
                            child: Text(n.numero, style: t.serif(22, cor: CuidaCores.verde700)),
                          ),
                          onTap: () => abrirArtigo(context, n.topico),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Semantics(header: true, child: Text('Para você', style: t.serif(24, lh: 29))),
                const SizedBox(height: 14),
                CartaoTint(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  onTap: () => shell.irPara(Aba.aprenda),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Urgência e emergência · 4 min',
                          style: t.sans(13, peso: FontWeight.w500, cor: CuidaCores.verdeTexto)),
                      const SizedBox(height: 10),
                      Text('UBS, UPA ou pronto-socorro: onde procurar atendimento?', style: t.serif(22, lh: 27)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ListaSeparada(
                  linhaNoFim: true,
                  children: [
                    for (final (titulo, meta) in const [
                      ('Seus direitos como usuário do SUS', 'Direitos · 3 min'),
                      ('Como funciona o calendário de vacinação', 'Prevenção · 5 min'),
                    ])
                      LinhaNavegacao(
                        titulo: titulo,
                        descricao: meta,
                        tituloEstilo: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alturaMinima: 0,
                        onTap: () => shell.irPara(Aba.aprenda),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                const RotuloSecao('Explorar assuntos', forte: true),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final assunto in assuntosExplorar)
                      OutlinedButton(
                        onPressed: () => shell.irPara(Aba.aprenda),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CuidaCores.azul,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          side: BorderSide(color: t.borda, width: t.larguraBorda),
                          shape: const StadiumBorder(),
                          textStyle: t.sans(14, peso: FontWeight.w500),
                        ),
                        child: Text(assunto),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque({required this.onConversar});

  final VoidCallback onConversar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: CuidaCores.azul, borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          const Positioned(right: -28, top: -14, child: RedeDecorativa.destaque()),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: CuidaCores.verde, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text('Assistente educativo',
                        style: t.sans(13, peso: FontWeight.w500, cor: CuidaCores.verdeClaro)),
                  ],
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Semantics(
                    header: true,
                    child: Text('Tire suas dúvidas sobre saúde',
                        style: t.serif(28, lh: 32, tracking: -0.01, cor: Colors.white)),
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 290),
                  child: Text(
                    'Entenda o SUS e saiba qual serviço procurar. Respostas simples, sempre com a fonte oficial.',
                    style: t.sans(15, lh: 23, cor: CuidaCores.sobreAzulTexto),
                  ),
                ),
                const SizedBox(height: 22),
                BotaoDestaque('Conversar com a IA', onPressed: onConversar),
                const SizedBox(height: 14),
                Text(
                  'Orienta, mas não faz diagnósticos. Não substitui um profissional de saúde.',
                  style: t.sans(12.5, lh: 18, cor: CuidaCores.sobreAzulApoio),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
