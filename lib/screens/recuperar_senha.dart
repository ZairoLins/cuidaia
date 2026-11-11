import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';

/// Folha inferior "Recuperar senha": envia o link de nova senha do Firebase.
Future<void> mostrarRecuperarSenha(BuildContext context, {String email = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CuidaCores.tinta.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(CuidaRaio.modal))),
    builder: (_) => _RecuperarSenha(emailInicial: email),
  );
}

class _RecuperarSenha extends StatefulWidget {
  const _RecuperarSenha({required this.emailInicial});

  final String emailInicial;

  @override
  State<_RecuperarSenha> createState() => _RecuperarSenhaState();
}

class _RecuperarSenhaState extends State<_RecuperarSenha> {
  late final _email = TextEditingController(text: widget.emailInicial.trim());
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!emailValido(_email.text)) {
      setState(() => _erro = 'Digite um e-mail válido, como nome@exemplo.com.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await AppScope.read(context).recuperarSenha(_email.text.trim());
      if (mounted) setState(() => _enviado = true);
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AlcaFolha(),
              const SizedBox(height: 14),
              Semantics(header: true, child: Text('Recuperar senha', style: t.titulo(26))),
              const SizedBox(height: 12),
              if (_enviado) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Se existir uma conta com ${_email.text.trim()}, você vai receber um link para criar uma nova senha. '
                    'Confira também a caixa de spam.',
                    style: t.sans(15, lh: 23, cor: t.mut),
                  ),
                ),
                const SizedBox(height: 20),
                BotaoPrimario('Entendi', onPressed: () => Navigator.pop(context)),
              ] else ...[
                Text(
                  'Informe o e-mail da sua conta. Enviaremos um link para você criar uma nova senha.',
                  style: t.sans(15, lh: 23, cor: t.mut),
                ),
                const SizedBox(height: 20),
                CuidaCampo(
                  rotulo: 'E-mail',
                  controller: _email,
                  dica: 'nome@exemplo.com',
                  limite: LimiteCampo.email,
                  teclado: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  acaoTeclado: TextInputAction.send,
                  aoEnviar: (_) => _enviar(),
                  erro: _erro,
                ),
                const SizedBox(height: 20),
                BotaoPrimario('Enviar link', carregando: _enviando, onPressed: _enviar),
                const SizedBox(height: 10),
                BotaoSecundario('Cancelar', onPressed: () => Navigator.pop(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
