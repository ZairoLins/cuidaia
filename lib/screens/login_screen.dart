import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'cadastro_screen.dart';
import 'confirmar_email_screen.dart';
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
  bool _entrandoGoogle = false;

  /// Falha de login (credenciais, Google, rede): aviso no topo do formulário.
  String? _erroConta;
  String? _erroEmail;
  String? _erroSenha;

  bool get _ocupado => _entrando || _entrandoGoogle;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_ocupado) return;
    final emailOk = emailValido(_email.text);
    final senhaOk = _senha.text.isNotEmpty;
    setState(() {
      _erroEmail = emailOk ? null : 'Informe um e-mail válido.';
      _erroSenha = senhaOk ? null : 'Informe sua senha.';
      _erroConta = null;
    });
    if (!emailOk || !senhaOk) return;

    FocusScope.of(context).unfocus();
    setState(() => _entrando = true);
    try {
      await AppScope.read(context).entrar(_email.text, _senha.text);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      abrirTelaDaSessao(context);
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erroConta = e.mensagem);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    if (_ocupado) return;
    setState(() {
      _entrandoGoogle = true;
      _erroConta = null;
    });
    try {
      await AppScope.read(context).entrarComGoogle();
      if (!mounted) return;
      abrirTelaDaSessao(context);
    } on ErroConta catch (e) {
      if (mounted && !e.cancelado) setState(() => _erroConta = e.mensagem);
    } finally {
      if (mounted) setState(() => _entrandoGoogle = false);
    }
  }

  void _esqueciSenha() => mostrarRecuperarSenha(context, email: _email.text);

  void _abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: CuidaLogo()),
                      const SizedBox(height: 28),
                      Semantics(header: true, child: Text('Entrar', style: t.titulo(26, lh: 32))),
                      const SizedBox(height: 28),
                      if (_erroConta != null) ...[
                        Aviso(tipo: TipoAviso.erro, texto: _erroConta!),
                        const SizedBox(height: 16),
                      ],
                      BotaoGoogle(carregando: _entrandoGoogle, onPressed: _ocupado ? null : _entrarComGoogle),
                      const SizedBox(height: 16),
                      ExcludeSemantics(
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: t.linha, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'ou com e-mail',
                                style: t.sans(13, peso: FontWeight.w600, cor: CuidaCores.apoioClaro),
                              ),
                            ),
                            Expanded(child: Divider(color: t.linha, height: 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CuidaCampo(
                        rotulo: 'E-mail',
                        controller: _email,
                        dica: 'nome@exemplo.com',
                        limite: LimiteCampo.email,
                        teclado: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                        acaoTeclado: TextInputAction.next,
                        erro: _erroEmail,
                        invalido: _erroConta != null,
                        onChanged: (_) {
                          if (_erroConta != null) setState(() => _erroConta = null);
                        },
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
                        invalido: _erroConta != null,
                        onChanged: (_) {
                          if (_erroConta != null) setState(() => _erroConta = null);
                        },
                        acaoRotulo: BotaoLink('Esqueci minha senha', onPressed: _esqueciSenha),
                        sufixo: BotaoVerSenha(
                          visivel: _verSenha,
                          onPressed: () => setState(() => _verSenha = !_verSenha),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BotaoPrimario(
                        _entrando ? 'Entrando…' : 'Entrar',
                        carregando: _entrando,
                        onPressed: _ocupado ? null : _entrar,
                      ),
                      const SizedBox(height: 28),
                      TextoComLinks(
                        alinhamento: TextAlign.center,
                        estilo: t.sans(14.5, cor: t.mut),
                        trechos: [
                          const TrechoTexto('Ainda não tem conta? '),
                          TrechoTexto('Criar conta', onTap: () => _abrir(const CadastroScreen())),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TextoComLinks(
                        alinhamento: TextAlign.center,
                        estilo: t.sans(12.5, lh: 19, cor: CuidaCores.apoioClaro),
                        corLink: t.mut,
                        sublinhado: true,
                        trechos: [
                          const TrechoTexto('Ao continuar, você concorda com os '),
                          TrechoTexto('Termos', onTap: () => _abrir(const TermosScreen())),
                          const TrechoTexto(' e a '),
                          TrechoTexto('Privacidade', onTap: () => _abrir(const PrivacidadeScreen())),
                          const TrechoTexto('.'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
