import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';
import '../recuperar_senha.dart';

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _conf = TextEditingController();
  bool _ver = false;
  bool _tentou = false;
  bool _ok = false;
  bool _salvando = false;
  String? _erroAtual;
  String? _erroServidor;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _conf.dispose();
    super.dispose();
  }

  List<RequisitoSenha> get _reqs => [
        ...requisitosSenha(_nova.text),
        RequisitoSenha('Diferente da atual', _nova.text.isNotEmpty && _nova.text != _atual.text),
      ];
  bool get _novaOk => _reqs.every((r) => r.ok);
  bool get _confOk => _conf.text.isNotEmpty && _conf.text == _nova.text;

  Future<void> _salvar() async {
    if (_salvando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _tentou = true;
      _erroAtual = null;
      _erroServidor = null;
    });
    if (_atual.text.isEmpty || !_novaOk || !_confOk) return;

    setState(() => _salvando = true);
    try {
      await AppScope.read(context).alterarSenha(atual: _atual.text, nova: _nova.text);
      if (mounted) setState(() => _ok = true);
    } on ErroConta catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.mensagem.contains('senha atual')) {
          _erroAtual = e.mensagem;
        } else {
          _erroServidor = e.mensagem;
        }
      });
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    void atualizar(String _) => setState(() {});

    return TelaInterna(
      titulo: 'Alterar senha',
      subtitulo: 'Por segurança, confirme a senha atual antes de criar uma nova.',
      children: [
        if (_ok)
          Semantics(
            liveRegion: true,
            child: Cartao(
              raio: 22,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.check_circle_outline_rounded, size: 36, color: CuidaCores.verde700),
                  ),
                  const SizedBox(height: 12),
                  Text('Senha alterada', style: t.serif(23)),
                  const SizedBox(height: 12),
                  Text(
                    'Use a nova senha na próxima vez que entrar. Se não foi você quem pediu a troca, use "Esqueci minha senha" na tela de entrada.',
                    style: t.sans(14.5, lh: 22, cor: t.mut),
                  ),
                  const SizedBox(height: 16),
                  BotaoPrimario('Voltar ao perfil', altura: 52, onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          )
        else
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CuidaCampo(
                  rotulo: 'Senha atual',
                  controller: _atual,
                  oculto: !_ver,
                  autofill: const [AutofillHints.password],
                  acaoRotulo: BotaoLink(
                    'Esqueci',
                    tamanho: 13.5,
                    onPressed: () => mostrarRecuperarSenha(context, email: AppScope.read(context).usuario.email),
                  ),
                  erro: _tentou && _atual.text.isEmpty ? 'Informe sua senha atual.' : _erroAtual,
                  onChanged: atualizar,
                ),
                const SizedBox(height: 20),
                CuidaCampo(
                  rotulo: 'Nova senha',
                  controller: _nova,
                  oculto: !_ver,
                  autofill: const [AutofillHints.newPassword],
                  invalido: _tentou && !_novaOk,
                  valido: _novaOk,
                  onChanged: atualizar,
                  abaixo: RequisitosSenha(itens: _reqs, tentou: _tentou),
                ),
                const SizedBox(height: 20),
                CuidaCampo(
                  rotulo: 'Confirmar nova senha',
                  controller: _conf,
                  oculto: !_ver,
                  autofill: const [AutofillHints.newPassword],
                  erro: _tentou && !_confOk ? 'As senhas não coincidem.' : null,
                  valido: _confOk,
                  onChanged: atualizar,
                ),
                const SizedBox(height: 12),
                MergeSemantics(
                  child: InkWell(
                    onTap: () => setState(() => _ver = !_ver),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(value: _ver, onChanged: (v) => setState(() => _ver = v ?? false)),
                          ),
                          const SizedBox(width: 12),
                          Text('Mostrar senhas', style: t.sans(15)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_erroServidor != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(_erroServidor!,
                        style: t.sans(14, lh: 21, peso: FontWeight.w500, cor: CuidaCores.erro)),
                  ),
                  const SizedBox(height: 12),
                ],
                BotaoPrimario('Salvar nova senha', carregando: _salvando, onPressed: _salvar),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: CuidaCores.azul,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: t.sans(15, peso: FontWeight.w600),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
