import 'package:flutter/foundation.dart';

/// Dados do perfil. Nenhuma informação de saúde fica aqui.
@immutable
class Usuario {
  const Usuario({required this.nome, this.apelido = '', required this.email, this.foto, this.temSenha = true});

  static const vazio = Usuario(nome: '', email: '');

  final String nome;
  final String apelido;
  final String email;

  /// `false` quando a pessoa entra só com o Google: não há senha para alterar
  /// nem para confirmar, e o e-mail é o da conta Google.
  final bool temSenha;

  /// Foto pequena (JPEG até 256 px), guardada no próprio perfil.
  final Uint8List? foto;

  String get iniciais {
    final partes = nome.split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }

  String get primeiroNome {
    final base = apelido.trim().isNotEmpty ? apelido : nome;
    return base.trim().split(' ').first;
  }

  Usuario copyWith({String? nome, String? apelido, String? email, Uint8List? foto, bool semFoto = false}) => Usuario(
    nome: nome ?? this.nome,
    apelido: apelido ?? this.apelido,
    email: email ?? this.email,
    foto: semFoto ? null : (foto ?? this.foto),
    temSenha: temSenha,
  );
}

/// Falha de conta com mensagem pronta para mostrar na tela.
class ErroConta implements Exception {
  const ErroConta(this.mensagem, {this.precisaSenha = false, this.cancelado = false});

  /// A pessoa fechou a janela do Google: não há o que mostrar.
  const ErroConta.cancelado() : this('', cancelado: true);

  final String mensagem;
  final bool cancelado;

  /// A operação exige confirmar a senha de novo (login recente).
  final bool precisaSenha;

  @override
  String toString() => mensagem;
}

/// Autenticação e perfil. Em produção: [ContaFirebase]; nos testes: [ContaMemoria].
abstract class Conta {
  /// Usuário com sessão ativa ao abrir o app, se houver.
  Future<Usuario?> sessaoAtual();

  Future<Usuario> entrar(String email, String senha);

  /// Entra com a conta Google. Na primeira vez, cria o perfil com o nome e o
  /// e-mail do Google. Lança [ErroConta.cancelado] se a pessoa desistir.
  Future<Usuario> entrarComGoogle();

  /// Cria a conta e envia o e-mail de confirmação.
  Future<Usuario> criar({required String nome, required String email, required String senha});

  Future<void> recuperarSenha(String email);

  Future<void> alterarSenha({required String atual, required String nova});

  /// Salva nome, apelido e foto. Se o e-mail mudar, envia um link de
  /// confirmação para o novo endereço; ele só vale depois de confirmado.
  /// Retorna `true` quando um link de troca de e-mail foi enviado.
  Future<bool> salvarPerfil(Usuario usuario);

  Future<void> sair();

  /// Apaga o perfil e a conta. Pede a senha para confirmar; sem senha
  /// (conta Google), pede para confirmar de novo com o Google.
  Future<void> excluir(String? senha);
}

/// Conta em memória, sem rede. Usada nos testes.
class ContaMemoria implements Conta {
  ContaMemoria({Map<String, (String senha, Usuario usuario)>? contas, String? logado, this.contaGoogle})
    : _contas = contas ?? {},
      _logado = logado; // ignore: prefer_initializing_formals (parâmetro nomeado público)

  /// Conta devolvida pelo "Entrar com Google"; `null` simula a pessoa desistir.
  final Usuario? contaGoogle;

  final Map<String, (String senha, Usuario usuario)> _contas;
  String? _logado;
  final List<String> emailsRecuperacao = [];

  @override
  Future<Usuario?> sessaoAtual() async => _logado == null ? null : _contas[_logado]?.$2;

  @override
  Future<Usuario> entrar(String email, String senha) async {
    final conta = _contas[email.trim().toLowerCase()];
    if (conta == null || conta.$1 != senha) throw const ErroConta('E-mail ou senha incorretos.');
    _logado = email.trim().toLowerCase();
    return conta.$2;
  }

  @override
  Future<Usuario> entrarComGoogle() async {
    final g = contaGoogle;
    if (g == null) throw const ErroConta.cancelado();
    _contas.putIfAbsent(g.email, () => ('', g));
    _logado = g.email;
    return _contas[g.email]!.$2;
  }

  @override
  Future<Usuario> criar({required String nome, required String email, required String senha}) async {
    final chave = email.trim().toLowerCase();
    if (_contas.containsKey(chave)) throw const ErroConta('Já existe uma conta com este e-mail.');
    final u = Usuario(nome: nome, apelido: nome.split(' ').first, email: chave);
    _contas[chave] = (senha, u);
    _logado = chave;
    return u;
  }

  @override
  Future<void> recuperarSenha(String email) async => emailsRecuperacao.add(email);

  @override
  Future<void> alterarSenha({required String atual, required String nova}) async {
    final conta = _contas[_logado];
    if (conta == null || conta.$1 != atual) throw const ErroConta('A senha atual está incorreta.');
    _contas[_logado!] = (nova, conta.$2);
  }

  @override
  Future<bool> salvarPerfil(Usuario usuario) async {
    final conta = _contas[_logado]!;
    final mudouEmail = usuario.email != conta.$2.email;
    _contas[_logado!] = (conta.$1, usuario.copyWith(email: conta.$2.email));
    return mudouEmail;
  }

  @override
  Future<void> sair() async => _logado = null;

  @override
  Future<void> excluir(String? senha) async {
    final conta = _contas[_logado];
    if (conta == null || (conta.$2.temSenha && conta.$1 != senha)) {
      throw const ErroConta('A senha está incorreta.');
    }
    _contas.remove(_logado);
    _logado = null;
  }
}
