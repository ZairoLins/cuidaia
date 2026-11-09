import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import 'aprenda_screen.dart';
import 'chat_screen.dart';
import 'inicio_screen.dart';
import 'perfil/perfil_screen.dart';

enum Aba {
  inicio('Início', Icons.home_outlined, Icons.home_rounded),
  chat('Assistente', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
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

/// Item ativo: pílula verde 50 atrás do ícone, ícone preenchido e rótulo em negrito — nunca só a cor.
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
        border: Border(
          top: BorderSide(color: t.linha, width: t.larguraBorda),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
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
    final cor = ativo ? CuidaCores.acaoEscuro : t.mut;
    return Semantics(
      selected: ativo,
      button: true,
      label: aba.rotulo,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CuidaRaio.botao),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: t.duracao(const Duration(milliseconds: 160)),
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  color: ativo ? (t.altoContraste ? Colors.white : CuidaCores.verde50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: ativo && t.altoContraste ? Border.all(color: CuidaCores.acaoEscuro, width: 1.5) : null,
                ),
                child: Icon(ativo ? aba.iconeAtivo : aba.icone, size: 21, color: cor),
              ),
              const SizedBox(height: 3),
              Text(
                aba.rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.sans(11.5, peso: ativo ? FontWeight.w700 : FontWeight.w600, cor: cor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
