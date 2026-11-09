import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/app_state.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';
import '../login_screen.dart';
import 'privacidade_screen.dart';

class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  bool _copiaGerada = false;
  bool _confirmandoExclusao = false;

  /// Gera um arquivo JSON com os dados e abre o compartilhamento do
  /// aparelho (na web, o arquivo é baixado).
  Future<void> _baixarCopia() async {
    final dados = AppScope.read(context).exportarDados();
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(dados));
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/json', name: 'cuidaia-meus-dados.json')],
          fileNameOverrides: ['cuidaia-meus-dados.json'],
          subject: 'Meus dados no CuidaIA',
          downloadFallbackEnabled: true,
        ),
      );
      if (mounted) setState(() => _copiaGerada = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Não foi possível gerar o arquivo. Tente de novo.')));
    }
  }

  Future<void> _excluir(String? senha) async {
    final estado = AppScope.read(context);
    final navegador = Navigator.of(context, rootNavigator: true);
    await estado.excluirConta(senha);
    navegador.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final estado = AppScope.of(context);
    final u = estado.usuario;
    final perguntas = estado.chat.totalPerguntas;
    final dados = [
      ('Nome', u.nome),
      ('E-mail', u.email),
      ('Preferências', 'Acessibilidade e notificações'),
      ('Conversas', perguntas == 0 ? 'Nenhuma' : (perguntas == 1 ? '1 pergunta' : '$perguntas perguntas')),
    ];

    Widget acao({required String titulo, required String descricao, required Widget controle}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.linha)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: t.sans(15, peso: FontWeight.w700, cor: CuidaCores.tinta),
          ),
          const SizedBox(height: 3),
          Text(descricao, style: t.sans(14, lh: 21, cor: t.mut)),
          const SizedBox(height: 12),
          controle,
        ],
      ),
    );

    Widget confirmado(String texto) => Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: CuidaCores.sucesso),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: t.sans(14, peso: FontWeight.w600, cor: CuidaCores.sucessoTexto),
            ),
          ),
        ],
      ),
    );

    return TelaInterna(
      titulo: 'Meus dados',
      subtitulo:
          'Veja o que o CuidaIA guarda sobre você e decida o que fazer com cada informação, como garante a LGPD.',
      espaco: 28,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('O que guardamos'),
            const SizedBox(height: 10),
            Cartao(
              child: ListaSeparada(
                children: [
                  for (final (rotulo, valor) in dados)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rotulo, style: t.sans(14, cor: t.mut)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              valor,
                              textAlign: TextAlign.right,
                              style: t.sans(14, peso: FontWeight.w700, cor: CuidaCores.tinta),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Nenhuma informação sobre a sua saúde é guardada no seu perfil.',
                style: t.sans(13, lh: 19, cor: t.mut),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RotuloSecao('O que você pode fazer'),
            const SizedBox(height: 4),
            acao(
              titulo: 'Baixar uma cópia',
              descricao: 'Gera na hora um arquivo com todos os seus dados, para você guardar ou enviar.',
              controle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BotaoCompacto('Baixar cópia', preenchido: true, onPressed: _baixarCopia),
                  if (_copiaGerada) ...[const SizedBox(height: 10), confirmado('Arquivo gerado.')],
                ],
              ),
            ),
            acao(
              titulo: 'Apagar histórico de conversas',
              descricao: 'Remove perguntas e respostas do assistente. Sua conta continua ativa.',
              controle: perguntas == 0
                  ? confirmado('Nenhuma conversa guardada.')
                  : BotaoCompacto('Apagar histórico', preenchido: true, onPressed: estado.apagarHistorico),
            ),
            acao(
              titulo: 'Excluir minha conta',
              descricao: 'Apaga a conta e todos os dados associados. Não pode ser desfeito.',
              controle: _confirmandoExclusao
                  ? _ConfirmarExclusao(
                      pedirSenha: u.temSenha,
                      onCancelar: () => setState(() => _confirmandoExclusao = false),
                      onExcluir: _excluir,
                    )
                  : BotaoCompacto(
                      'Excluir conta',
                      destrutivo: true,
                      preenchido: true,
                      onPressed: () => setState(() => _confirmandoExclusao = true),
                    ),
            ),
          ],
        ),
        TextoComLinks(
          estilo: t.sans(14, lh: 21, cor: t.mut),
          corLink: CuidaCores.acao,
          trechos: [
            const TrechoTexto('Saiba mais na '),
            TrechoTexto(
              'Política de privacidade',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacidadeScreen())),
            ),
            const TrechoTexto('.'),
          ],
        ),
      ],
    );
  }
}

class _ConfirmarExclusao extends StatefulWidget {
  const _ConfirmarExclusao({required this.pedirSenha, required this.onCancelar, required this.onExcluir});

  /// `false` para contas Google: a confirmação abre a janela do Google.
  final bool pedirSenha;
  final VoidCallback onCancelar;

  /// Recebe a senha digitada (ou `null`); lança [ErroConta] se algo falhar.
  final Future<void> Function(String? senha) onExcluir;

  @override
  State<_ConfirmarExclusao> createState() => _ConfirmarExclusaoState();
}

class _ConfirmarExclusaoState extends State<_ConfirmarExclusao> {
  final _senha = TextEditingController();
  bool _excluindo = false;
  String? _erro;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _excluir() async {
    if (_excluindo) return;
    if (widget.pedirSenha && _senha.text.isEmpty) {
      setState(() => _erro = 'Digite sua senha para confirmar.');
      return;
    }
    setState(() {
      _excluindo = true;
      _erro = null;
    });
    try {
      await widget.onExcluir(widget.pedirSenha ? _senha.text : null);
    } on ErroConta catch (e) {
      if (mounted && !e.cancelado) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CuidaCores.erroFundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CuidaCores.erroLinha),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Tem certeza? ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: 'Você perderá o histórico, os conteúdos salvos e as preferências.'),
                ],
              ),
              style: t.sans(14, lh: 21, cor: CuidaCores.erroTitulo),
            ),
            const SizedBox(height: 14),
            if (widget.pedirSenha)
              CuidaCampo(
                rotulo: 'Sua senha',
                controller: _senha,
                oculto: true,
                autofill: const [AutofillHints.password],
                acaoTeclado: TextInputAction.done,
                aoEnviar: (_) => _excluir(),
                erro: _erro,
              )
            else ...[
              Text(
                'Para confirmar, vamos pedir que você escolha de novo a sua conta Google.',
                style: t.sans(14, lh: 21, cor: CuidaCores.erroTitulo),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erro!,
                  style: t.sans(13, peso: FontWeight.w500, cor: CuidaCores.erro),
                ),
              ],
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _excluindo ? null : widget.onCancelar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CuidaCores.tinta,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: t.bordaBotao, width: t.larguraBorda),
                      minimumSize: const Size.fromHeight(48),
                      shape: CuidaRaio.formaBotao,
                      textStyle: t.sans(15, peso: FontWeight.w700),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BotaoPrimario(
                    'Excluir',
                    altura: 48,
                    cor: CuidaCores.erro,
                    carregando: _excluindo,
                    onPressed: _excluir,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
