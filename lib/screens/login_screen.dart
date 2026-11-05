import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'cadastro_screen.dart';
import 'home_shell.dart';
import 'perfil/privacidade_screen.dart';
import 'perfil/termos_screen.dart';
import 'recuperar_senha.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _verSenha = false;
  bool _entrando = false;
  String? _erroEmail;
  String? _erroSenha;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    final emailOk = emailValido(_email.text);
    final senhaOk = _senha.text.isNotEmpty;
    setState(() {
      _erroEmail = emailOk ? null : 'Digite um e-mail válido, como nome@exemplo.com.';
      _erroSenha = senhaOk ? null : 'Informe sua senha.';
    });
    if (!emailOk || !senhaOk) return;

    FocusScope.of(context).unfocus();
    setState(() => _entrando = true);
    try {
      await AppScope.read(context).entrar(_email.text, _senha.text);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erroSenha = e.mensagem);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  void _esqueciSenha() => mostrarRecuperarSenha(context, email: _email.text);

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            right: -40,
            top: MediaQuery.paddingOf(context).top + 18,
            child: const Opacity(opacity: 0.7, child: RedeDecorativa.login()),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [CuidaSimbolo(tamanho: 34), SizedBox(width: 10), CuidaMarca(tamanho: 25)],
                          ),
                          const SizedBox(height: 44),
                          Semantics(
                            header: true,
                            child: Text(
                              'Saúde pública, explicada com cuidado.',
                              style: t.serif(36, lh: 40, tracking: -0.015),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Entenda como o SUS funciona, tire dúvidas e saiba qual serviço procurar.',
                            style: t.sans(16, lh: 25, cor: t.mut),
                          ),
                          const SizedBox(height: 32),
                          CuidaCampo(
                            rotulo: 'E-mail',
                            controller: _email,
                            dica: 'nome@exemplo.com',
                            teclado: TextInputType.emailAddress,
                            autofill: const [AutofillHints.email],
                            acaoTeclado: TextInputAction.next,
                            erro: _erroEmail,
                          ),
                          const SizedBox(height: 16),
                          CuidaCampo(
                            rotulo: 'Senha',
                            controller: _senha,
                            dica: 'Sua senha',
                            oculto: !_verSenha,
                            autofill: const [AutofillHints.password],
                            acaoTeclado: TextInputAction.done,
                            aoEnviar: (_) => _entrar(),
                            erro: _erroSenha,
                            acaoRotulo: BotaoLink('Esqueci minha senha', onPressed: _esqueciSenha),
                            sufixo: BotaoVerSenha(
                              visivel: _verSenha,
                              onPressed: () => setState(() => _verSenha = !_verSenha),
                            ),
                          ),
                          const SizedBox(height: 24),
                          BotaoPrimario('Entrar', carregando: _entrando, onPressed: _entrar),
                          const SizedBox(height: 10),
                          BotaoSecundario(
                            'Criar minha conta',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CadastroScreen()),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 32),
                          TextoComLinks(
                            alinhamento: TextAlign.center,
                            estilo: t.sans(13, lh: 20, cor: t.mut),
                            trechos: [
                              const TrechoTexto('Ao entrar, você concorda com os '),
                              TrechoTexto('Termos de uso', onTap: () => _abrir(const TermosScreen())),
                              const TrechoTexto(' e a '),
                              TrechoTexto('Política de privacidade', onTap: () => _abrir(const PrivacidadeScreen())),
                              const TrechoTexto('.'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
}
