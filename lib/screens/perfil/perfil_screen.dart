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
        const SizedBox(height: 8),
        Cartao(child: ListaSeparada(children: itens)),
      ],
    );

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Semantics(header: true, child: Text('Perfil', style: t.titulo(26, lh: 32))),
              const SizedBox(height: 24),
              Cartao(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AvatarIniciais(iniciais: u.iniciais, foto: u.foto),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.nome, style: t.sans(16.5, lh: 22, peso: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(u.email, style: t.sans(13.5, cor: t.mut)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    BotaoCompacto('Editar', onPressed: () => abrir(const EditarPerfilScreen())),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              grupo('Conta', [
                LinhaNavegacao(
                  titulo: 'Informações pessoais',
                  icone: Icons.person_outline_rounded,
                  onTap: () => abrir(const EditarPerfilScreen()),
                ),
                if (u.temSenha)
                  LinhaNavegacao(
                    titulo: 'Alterar senha',
                    icone: Icons.lock_outline_rounded,
                    onTap: () => abrir(const AlterarSenhaScreen()),
                  ),
              ]),
              const SizedBox(height: 24),
              grupo('Preferências', [
                LinhaNavegacao(
                  titulo: 'Acessibilidade',
                  descricao: estado.a11y.resumo,
                  icone: Icons.text_fields_rounded,
                  onTap: () => abrir(const AcessibilidadeScreen()),
                ),
                LinhaNavegacao(
                  titulo: 'Notificações',
                  descricao: 'Dica da semana e lembretes de leitura',
                  icone: Icons.notifications_none_rounded,
                  onTap: () => abrir(const NotificacoesScreen()),
                ),
              ]),
              const SizedBox(height: 24),
              grupo('Privacidade', [
                LinhaNavegacao(
                  titulo: 'Meus dados',
                  descricao: 'Consultar, baixar ou excluir (LGPD)',
                  icone: Icons.storage_rounded,
                  onTap: () => abrir(const MeusDadosScreen()),
                ),
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
              ]),
              const SizedBox(height: 24),
              Cartao(
                onTap: () => mostrarSairConta(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, size: 20, color: CuidaCores.erro),
                        const SizedBox(width: 12),
                        Text(
                          'Sair da conta',
                          style: t.sans(15, peso: FontWeight.w800, cor: CuidaCores.erro),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: NotaApoio(
                  texto:
                      'Seu perfil guarda apenas nome e e-mail. Nenhuma informação sobre a sua saúde fica salva aqui.',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CuidaIA 1.0 · protótipo acadêmico',
                textAlign: TextAlign.center,
                style: t.sans(12.5, cor: t.mut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
