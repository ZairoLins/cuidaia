import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'perfil/sair_conta.dart';

/// Tela certa para o estado da sessão: Login (sem sessão), "Confirme seu
/// e-mail" (conta criada, link ainda não aberto) ou o app.
Widget telaDaSessao(AppState estado) {
  if (!estado.logado) return const LoginScreen();
  return estado.liberado ? const HomeShell() : const ConfirmarEmailScreen();
}

/// Substitui a tela atual (e as anteriores) pela tela da sessão.
void abrirTelaDaSessao(BuildContext context) {
  final estado = AppScope.read(context);
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => telaDaSessao(estado)), (_) => false);
}

/// Quem criou a conta com e-mail e senha só entra no app depois de abrir o
/// link de confirmação. Assim ninguém usa uma conta com o e-mail de outra pessoa.
class ConfirmarEmailScreen extends StatefulWidget {
  const ConfirmarEmailScreen({super.key});

  /// Intervalo mínimo entre dois envios do link.
  static const esperaReenvio = Duration(seconds: 60);

  @override
  State<ConfirmarEmailScreen> createState() => _ConfirmarEmailScreenState();
}

class _ConfirmarEmailScreenState extends State<ConfirmarEmailScreen> {
  bool _verificando = false;
  bool _reenviando = false;
  bool _reenviado = false;
  String? _erro;
  Timer? _espera;

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_verificando) return;
    setState(() {
      _verificando = true;
      _erro = null;
    });
    try {
      final confirmado = await AppScope.read(context).verificarConfirmacao();
      if (!mounted) return;
      if (confirmado) {
        abrirTelaDaSessao(context);
      } else {
        setState(() => _erro = 'Ainda não recebemos a confirmação. Abra o link que enviamos e toque de novo aqui.');
      }
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _reenviar() async {
    if (_reenviando || _reenviado) return;
    setState(() {
      _reenviando = true;
      _erro = null;
    });
    try {
      await AppScope.read(context).reenviarConfirmacao();
      if (!mounted) return;
      setState(() => _reenviado = true);
      _espera = Timer(ConfirmarEmailScreen.esperaReenvio, () {
        if (mounted) setState(() => _reenviado = false);
      });
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final email = AppScope.of(context).usuario.email;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: CuidaLogo()),
                    const SizedBox(height: 28),
                    Semantics(header: true, child: Text('Confirme seu e-mail', style: t.titulo(26, lh: 32))),
                    const SizedBox(height: 12),
                    Text(
                      'Enviamos um link de confirmação para $email. Abra o link e depois toque em "Já confirmei".',
                      style: t.sans(15, lh: 23, cor: t.mut),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Não encontrou? Confira a caixa de spam.',
                      style: t.sans(14, lh: 21, cor: t.mut),
                    ),
                    const SizedBox(height: 24),
                    if (_erro != null) ...[MensagemErro(_erro!), const SizedBox(height: 12)],
                    if (_reenviado) ...[
                      const AvisoSucesso(texto: 'Link enviado de novo. Você pode pedir outro em 1 minuto.'),
                      const SizedBox(height: 12),
                    ],
                    BotaoPrimario('Já confirmei', carregando: _verificando, onPressed: _verificar),
                    const SizedBox(height: 10),
                    BotaoSecundario(
                      _reenviando ? 'Enviando…' : 'Reenviar o link',
                      onPressed: _reenviando || _reenviado ? null : _reenviar,
                    ),
                    const SizedBox(height: 16),
                    Center(child: BotaoLink('Sair e usar outra conta', onPressed: () => encerrarSessao(context))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
