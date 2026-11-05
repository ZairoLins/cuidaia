import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';
import 'acessibilidade_screen.dart';
import 'alterar_senha_screen.dart';
import 'editar_perfil_screen.dart';
import 'meus_dados_screen.dart';
import 'notificacoes_screen.dart';
import 'privacidade_screen.dart';
import 'sair_conta.dart';
import 'termos_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final estado = AppScope.of(context);
    final u = estado.usuario;
    void abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

    Widget grupo(String titulo, List<Widget> itens) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RotuloSecao(titulo),
            const SizedBox(height: 10),
            Cartao(child: ListaSeparada(children: itens)),
          ],
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
        children: [
          Semantics(header: true, child: Text('Perfil', style: t.serif(34, lh: 39, tracking: -0.015))),
          const SizedBox(height: 32),
          Row(
            children: [
              AvatarIniciais(iniciais: u.iniciais, foto: u.foto),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.nome, style: t.serif(21, lh: 26)),
                    const SizedBox(height: 2),
                    Text(u.email, style: t.sans(14, cor: t.mut)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          BotaoSecundario('Editar perfil', altura: 48, onPressed: () => abrir(const EditarPerfilScreen())),
          const SizedBox(height: 32),
          grupo('Conta', [
            LinhaNavegacao(
              titulo: 'Informações cadastrais',
              icone: Icons.person_outline_rounded,
              onTap: () => abrir(const EditarPerfilScreen()),
            ),
            LinhaNavegacao(
              titulo: 'Alterar senha',
              icone: Icons.lock_outline_rounded,
              onTap: () => abrir(const AlterarSenhaScreen()),
            ),
          ]),
          const SizedBox(height: 32),
          grupo('Preferências', [
            LinhaNavegacao(
              titulo: 'Acessibilidade',
              descricao: estado.a11y.resumo,
              icone: Icons.text_fields_rounded,
              onTap: () => abrir(const AcessibilidadeScreen()),
            ),
            LinhaNavegacao(
              titulo: 'Notificações',
              descricao: 'Conteúdos, lembretes e novidades',
              icone: Icons.notifications_none_rounded,
              onTap: () => abrir(const NotificacoesScreen()),
            ),
          ]),
          const SizedBox(height: 32),
          grupo('Privacidade e termos', [
            LinhaNavegacao(
              titulo: 'Política de privacidade',
              icone: Icons.shield_outlined,
              onTap: () => abrir(const PrivacidadeScreen()),
            ),
            LinhaNavegacao(
              titulo: 'Termos de uso',
              icone: Icons.description_outlined,
              onTap: () => abrir(const TermosScreen()),
            ),
            LinhaNavegacao(
              titulo: 'Meus dados (LGPD)',
              descricao: 'Consultar, baixar ou excluir',
              icone: Icons.folder_shared_outlined,
              onTap: () => abrir(const MeusDadosScreen()),
            ),
          ]),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: NotaApoio(
              texto: 'Seu perfil guarda apenas nome e e-mail. Nenhuma informação sobre a sua saúde fica salva aqui.',
            ),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => mostrarSairConta(context),
            style: TextButton.styleFrom(
              foregroundColor: CuidaCores.erro,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: t.sans(16, peso: FontWeight.w600),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Sair da conta'),
          ),
          const SizedBox(height: 12),
          Text('CuidaIA 1.0 · protótipo acadêmico', textAlign: TextAlign.center, style: t.sans(12.5, cor: t.mut)),
        ],
      ),
    );
  }
}
