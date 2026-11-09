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
    final nome = estado.usuario.primeiroNome;
    final leitura = artigos.containsKey(estado.continuarLendo?.topico) ? estado.continuarLendo : null;
    final artigoAtual = artigos[leitura?.topico] ?? artigos['primaria']!;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome.isEmpty ? 'Olá!' : 'Olá, $nome',
                          style: t.sans(14, peso: FontWeight.w600, cor: t.mut),
                        ),
                        const SizedBox(height: 2),
                        Semantics(header: true, child: Text('Como podemos ajudar?', style: t.titulo(24, lh: 30))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _BotaoQuadrado(
                    rotulo: 'Notificações',
                    icone: Icons.notifications_none_rounded,
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificacoesScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Ações principais: perguntar, onde ser atendido e 192.
              Semantics(
                container: true,
                label: 'Ações principais',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Perguntar(onTap: () => shell.abrirChat()),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Atalho(
                            texto: 'Onde ser atendido',
                            icone: Icons.location_on_outlined,
                            onTap: () => shell.abrirChat(orientacao: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Atalho(
                            texto: 'Emergência 192',
                            icone: Icons.call_outlined,
                            emergencia: true,
                            onTap: () => ligar(context, '192'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Último artigo não terminado; sem leitura em andamento, sugere o primeiro.
              RotuloSecao(leitura == null ? 'Comece por aqui' : 'Continue lendo'),
              const SizedBox(height: 10),
              Cartao(
                onTap: () => abrirArtigo(context, artigoAtual.topico),
                raio: 12,
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(artigoAtual.titulo, style: t.sans(15, peso: FontWeight.w700)),
                          const SizedBox(height: 8),
                          if (leitura == null)
                            Text('${artigoAtual.categoria} · ${artigoAtual.tempo}', style: t.sans(13, cor: t.mut))
                          else
                            Semantics(
                              label: 'Progresso de leitura',
                              value: '${(leitura.fracao * 100).round()}%',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: leitura.fracao,
                                  minHeight: 4,
                                  color: CuidaCores.acao,
                                  backgroundColor: CuidaCores.trilho,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: CuidaCores.apoioClaro),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(child: RotuloSecao('Níveis de atenção')),
                  BotaoLink('Ver tudo', onPressed: () => shell.irPara(Aba.aprenda)),
                ],
              ),
              Cartao(
                raio: 12,
                child: ListaSeparada(
                  children: [
                    for (final (i, n) in niveisAtencao.indexed)
                      LinhaNavegacao(
                        titulo: n.titulo,
                        inicio: NumeroNivel(i, tamanho: 30),
                        alturaMinima: 54,
                        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                        onTap: () => abrirArtigo(context, n.topico),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de entrada falso que abre o assistente: "Pergunte sobre o SUS…" + "Perguntar".
class _Perguntar extends StatelessWidget {
  const _Perguntar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      button: true,
      label: 'Perguntar ao assistente sobre o SUS',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.borda, width: t.larguraBorda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: CuidaCores.acao),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Pergunte sobre o SUS…', style: t.sans(15.5, cor: t.mut)),
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: CuidaCores.acao, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'Perguntar',
                      style: t.sans(14, peso: FontWeight.w700, cor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Atalho em grade: "Onde ser atendido" e "Emergência 192".
class _Atalho extends StatelessWidget {
  const _Atalho({required this.texto, required this.icone, required this.onTap, this.emergencia = false});

  final String texto;
  final IconData icone;
  final VoidCallback onTap;
  final bool emergencia;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final borda = t.altoContraste ? CuidaCores.tinta : (emergencia ? CuidaCores.erroLinha : CuidaCores.linha);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borda, width: t.larguraBorda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icone, size: 20, color: emergencia ? CuidaCores.erro : CuidaCores.acaoEscuro),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    texto,
                    style: t.sans(
                      14.5,
                      lh: 19,
                      peso: emergencia ? FontWeight.w800 : FontWeight.w700,
                      cor: emergencia ? CuidaCores.erroForte : CuidaCores.tinta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de ícone 44 × 44 com borda fina.
class _BotaoQuadrado extends StatelessWidget {
  const _BotaoQuadrado({required this.rotulo, required this.icone, required this.onTap});

  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return IconButton(
      onPressed: onTap,
      tooltip: rotulo,
      color: CuidaCores.tinta,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CuidaRaio.botao),
          side: BorderSide(color: t.linha, width: t.larguraBorda),
        ),
      ),
      icon: Icon(icone, size: 20),
    );
  }
}
