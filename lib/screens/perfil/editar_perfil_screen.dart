import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../state/app_state.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  /// A foto fica no próprio perfil (Firestore), então precisa ser pequena.
  static const _ladoFoto = 256.0;
  static const _limiteFoto = 300 * 1024;

  late final TextEditingController _nome;
  late final TextEditingController _apelido;
  late final TextEditingController _email;
  Uint8List? _foto;
  bool _salvando = false;
  String? _aviso;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final u = AppScope.read(context).usuario;
    _nome = TextEditingController(text: u.nome);
    _apelido = TextEditingController(text: u.apelido);
    _email = TextEditingController(text: u.email);
    _foto = u.foto;
  }

  @override
  void dispose() {
    _nome.dispose();
    _apelido.dispose();
    _email.dispose();
    super.dispose();
  }

  void _mudou(String _) {
    if (_aviso != null || _erro != null) {
      setState(() {
        _aviso = null;
        _erro = null;
      });
    }
  }

  Future<void> _escolherFoto() async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: _ladoFoto,
        maxHeight: _ladoFoto,
        imageQuality: 75,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _limiteFoto) {
        setState(() => _erro = 'Essa imagem é grande demais. Tente outra foto.');
        return;
      }
      setState(() {
        _foto = bytes;
        _aviso = null;
        _erro = null;
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível abrir a imagem. Tente outra foto.');
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    FocusScope.of(context).unfocus();
    final nome = _nome.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final email = _email.text.trim();
    if (nome.split(' ').length < 2) {
      setState(() => _erro = 'Informe nome e sobrenome.');
      return;
    }
    if (!emailValido(email)) {
      setState(() => _erro = 'Digite um e-mail válido, como nome@exemplo.com.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
      _aviso = null;
    });
    try {
      final estado = AppScope.read(context);
      final atual = estado.usuario;
      final mudouEmail = await estado.salvarUsuario(
        Usuario(nome: nome, apelido: _apelido.text.trim(), email: email, foto: _foto),
      );
      if (!mounted) return;
      setState(() {
        _aviso = mudouEmail
            ? 'Alterações salvas. Enviamos um link para $email: o novo e-mail passa a valer depois que você confirmar.'
            : 'Alterações salvas.';
        if (mudouEmail) _email.text = atual.email;
      });
    } on ErroConta catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final iniciais = Usuario(nome: _nome.text, email: '').iniciais;
    return TelaInterna(
      titulo: 'Editar perfil',
      espaco: 22,
      children: [
        if (_aviso != null)
          AvisoSucesso(
            texto: _aviso!,
            acao: BotaoLink('Ver perfil', onPressed: () => Navigator.pop(context)),
          ),
        Row(
          children: [
            AvatarIniciais(iniciais: iniciais, foto: _foto, tamanho: 72),
            const SizedBox(width: 16),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BotaoCompacto(_foto == null ? 'Adicionar foto' : 'Alterar foto', onPressed: _escolherFoto),
                  if (_foto != null)
                    BotaoCompacto('Remover', onPressed: () {
                      setState(() => _foto = null);
                      _mudou('');
                    }),
                ],
              ),
            ),
          ],
        ),
        CuidaCampo(
          rotulo: 'Nome completo',
          controller: _nome,
          autofill: const [AutofillHints.name],
          onChanged: (v) {
            _mudou(v);
            setState(() {});
          },
        ),
        CuidaCampo(
          rotulo: 'Como prefere ser chamada(o)?',
          rotuloOpcional: true,
          controller: _apelido,
          dica: 'Ex.: Maria',
          ajuda: 'Aparece na saudação da página inicial.',
          onChanged: _mudou,
        ),
        CuidaCampo(
          rotulo: 'E-mail',
          controller: _email,
          teclado: TextInputType.emailAddress,
          autofill: const [AutofillHints.email],
          ajuda: 'Se mudar o e-mail, enviaremos um link de confirmação para o novo endereço.',
          onChanged: _mudou,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_erro != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(_erro!, style: t.sans(14, lh: 21, peso: FontWeight.w500, cor: CuidaCores.erro)),
              ),
              const SizedBox(height: 12),
            ],
            BotaoPrimario('Salvar alterações', carregando: _salvando, onPressed: _salvar),
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
      ],
    );
  }
}
