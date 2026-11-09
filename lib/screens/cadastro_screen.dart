import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'home_shell.dart';
import 'perfil/privacidade_screen.dart';
import 'perfil/termos_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _conf = TextEditingController();
  bool _aceite = false;
  bool _tentou = false;
  bool _ok = false;
  bool _ver = false;
  bool _enviando = false;
  String? _erroServidor;

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha, _conf]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _nomeOk => _nome.text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length >= 2;
  bool get _emailOk => emailValido(_email.text);
  List<RequisitoSenha> get _reqs => requisitosSenha(_senha.text);
  bool get _senhaOk => _reqs.every((r) => r.ok);
  bool get _confOk => _conf.text.isNotEmpty && _conf.text == _senha.text;

  Future<void> _enviar() async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    final valido = _nomeOk && _emailOk && _senhaOk && _confOk && _aceite;
    setState(() {
      _tentou = true;
      _erroServidor = null;
    });
    if (!valido) return;

    setState(() => _enviando = true);
    try {
      await AppScope.read(context).criarConta(
        nome: _nome.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        email: _email.text.trim(),
        senha: _senha.text,
      );
      if (mounted) setState(() => _ok = true);
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erroServidor = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _comecar() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
  }

  void _abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CabecalhoVoltar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Semantics(header: true, child: Text('Criar sua conta', style: t.titulo(26, lh: 32))),
                  const SizedBox(height: 6),
                  Text(
                    'Leva menos de um minuto. Não pedimos nenhuma informação sobre a sua saúde.',
                    style: t.sans(14.5, lh: 21, cor: t.mut),
                  ),
                  const SizedBox(height: 24),
                  if (_ok) _sucesso(t) else _formulario(t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sucesso(CuidaTema t) {
    return Semantics(
      liveRegion: true,
      child: Cartao(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.check_circle_outline_rounded, size: 32, color: CuidaCores.sucesso),
            ),
            const SizedBox(height: 14),
            Text('Conta criada', style: t.titulo(20, lh: 26)),
            const SizedBox(height: 14),
            Text('Enviamos um link de confirmação para ${_email.text.trim()}.', style: t.sans(15, lh: 23, cor: t.mut)),
            const SizedBox(height: 20),
            BotaoPrimario('Começar', onPressed: _comecar),
          ],
        ),
      ),
    );
  }

  Widget _formulario(CuidaTema t) {
    final e = (
      nome: _tentou && !_nomeOk,
      email: _tentou && !_emailOk,
      senha: _tentou && !_senhaOk,
      conf: _tentou && !_confOk,
      aceite: _tentou && !_aceite,
    );
    final totalErros = [e.nome, e.email, e.senha, e.conf, e.aceite].where((x) => x).length;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (totalErros > 0) ...[
            Aviso(
              tipo: TipoAviso.erro,
              titulo: 'Quase lá.',
              texto: totalErros == 1 ? 'Revise 1 campo destacado.' : 'Revise $totalErros campos destacados.',
            ),
            const SizedBox(height: 20),
          ],
          CuidaCampo(
            rotulo: 'Nome completo',
            controller: _nome,
            dica: 'Como está no seu documento',
            autofill: const [AutofillHints.name],
            acaoTeclado: TextInputAction.next,
            erro: e.nome ? 'Informe nome e sobrenome.' : null,
            valido: _tentou && _nomeOk,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          CuidaCampo(
            rotulo: 'E-mail',
            controller: _email,
            dica: 'nome@exemplo.com',
            teclado: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            acaoTeclado: TextInputAction.next,
            erro: e.email ? 'Digite um e-mail válido, como nome@exemplo.com.' : null,
            valido: _tentou && _emailOk,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          CuidaCampo(
            rotulo: 'Senha',
            controller: _senha,
            dica: 'Crie uma senha',
            oculto: !_ver,
            autofill: const [AutofillHints.newPassword],
            acaoTeclado: TextInputAction.next,
            invalido: e.senha,
            valido: _senhaOk,
            onChanged: (_) => setState(() {}),
            sufixo: BotaoVerSenha(visivel: _ver, onPressed: () => setState(() => _ver = !_ver)),
            abaixo: RequisitosSenha(itens: _reqs, tentou: _tentou),
          ),
          const SizedBox(height: 20),
          CuidaCampo(
            rotulo: 'Confirmar senha',
            controller: _conf,
            dica: 'Repita a senha',
            oculto: !_ver,
            autofill: const [AutofillHints.newPassword],
            acaoTeclado: TextInputAction.done,
            erro: e.conf ? 'As senhas não coincidem.' : null,
            valido: _confOk,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _aceite,
                    onChanged: (v) => setState(() => _aceite = v ?? false),
                    side: BorderSide(color: e.aceite ? CuidaCores.erro : t.borda, width: 1.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextoComLinks(
                    estilo: t.sans(14, lh: 21),
                    corLink: CuidaCores.acao,
                    trechos: [
                      const TrechoTexto('Li e concordo com os '),
                      TrechoTexto('Termos de uso', onTap: () => _abrir(const TermosScreen())),
                      const TrechoTexto(' e com a '),
                      TrechoTexto('Política de privacidade', onTap: () => _abrir(const PrivacidadeScreen())),
                      const TrechoTexto(' (LGPD).'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (e.aceite)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: Text(
                'Para continuar, aceite os termos.',
                style: t.sans(13, peso: FontWeight.w500, cor: CuidaCores.erro),
              ),
            ),
          const SizedBox(height: 24),
          if (_erroServidor != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _erroServidor!,
                style: t.sans(14, lh: 21, peso: FontWeight.w500, cor: CuidaCores.erro),
              ),
            ),
            const SizedBox(height: 12),
          ],
          BotaoPrimario('Criar conta', carregando: _enviando, onPressed: _enviar),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Já tem conta?', style: t.sans(15, cor: t.mut)),
              BotaoLink('Entrar', tamanho: 15, onPressed: () => Navigator.maybePop(context)),
            ],
          ),
        ],
      ),
    );
  }
}
