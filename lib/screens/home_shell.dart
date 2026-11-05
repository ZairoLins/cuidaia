import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import 'aprenda_screen.dart';
import 'chat_screen.dart';
import 'inicio_screen.dart';
import 'perfil/perfil_screen.dart';

enum Aba {
  inicio('Início', Icons.home_outlined, Icons.home_rounded),
  chat('Chat', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
  aprenda('Aprenda', Icons.menu_book_outlined, Icons.menu_book_rounded),
  perfil('Perfil', Icons.person_outline_rounded, Icons.person_rounded);

  const Aba(this.rotulo, this.icone, this.iconeAtivo);
  final String rotulo;
  final IconData icone;
  final IconData iconeAtivo;
}

/// Estrutura com as quatro abas e a navegação inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState of(BuildContext context) => context.findAncestorStateOfType<HomeShellState>()!;

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  Aba _aba = Aba.inicio;

  void irPara(Aba aba) => setState(() => _aba = aba);

  /// Abre o chat; com [orientacao], já começa a pergunta "onde procurar atendimento".
  void abrirChat({bool orientacao = false}) {
    setState(() => _aba = Aba.chat);
    if (orientacao) AppScope.read(context).chat.iniciarOrientacao();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _aba == Aba.inicio,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) irPara(Aba.inicio);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _aba.index,
          children: const [InicioScreen(), ChatScreen(), AprendaScreen(), PerfilScreen()],
        ),
        bottomNavigationBar: NavInferior(ativa: _aba, aoSelecionar: irPara),
      ),
    );
  }
}

/// Item ativo: barra superior verde-água, ícone preenchido e rótulo em negrito — nunca só a cor.
class NavInferior extends StatelessWidget {
  const NavInferior({super.key, required this.ativa, required this.aoSelecionar});

  final Aba ativa;
  final ValueChanged<Aba> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: t.linha, width: t.larguraBorda)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          // Rótulos curtos: limita a ampliação para não estourar a barra.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              children: [
                for (final aba in Aba.values)
                  Expanded(
                    child: _ItemNav(aba: aba, ativo: aba == ativa, onTap: () => aoSelecionar(aba)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav({required this.aba, required this.ativo, required this.onTap});

  final Aba aba;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final cor = ativo ? CuidaCores.azul : t.mut;
    return Semantics(
      selected: ativo,
      button: true,
      label: aba.rotulo,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -4,
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: ativo ? CuidaCores.verde : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ativo ? aba.iconeAtivo : aba.icone, size: 24, color: cor),
                  const SizedBox(height: 4),
                  Text(
                    aba.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.sans(12, peso: ativo ? FontWeight.w700 : FontWeight.w500, cor: cor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
