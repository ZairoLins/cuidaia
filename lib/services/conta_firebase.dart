import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'conta.dart';

/// Conta com Firebase Authentication (e-mail e senha) e perfil no Cloud Firestore,
/// em `usuarios/{uid}`. Tudo dentro da cota gratuita (plano Spark).
class ContaFirebase implements Conta {
  ContaFirebase({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance {
    // E-mails de confirmação e de nova senha em português.
    _auth.setLanguageCode('pt');
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('usuarios').doc(uid);

  User get _user {
    final u = _auth.currentUser;
    if (u == null) throw const ErroConta('Sua sessão terminou. Entre de novo.');
    return u;
  }

  @override
  Future<Usuario?> sessaoAtual() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    try {
      await u.reload(); // pega o e-mail novo, se a troca já foi confirmada
      return await _carregarPerfil(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      // Conta apagada ou desativada em outro lugar: começa deslogado.
      if (e.code == 'user-not-found' || e.code == 'user-disabled' || e.code == 'user-token-expired') {
        await _auth.signOut();
        return null;
      }
      return _carregarPerfil(u);
    } on FirebaseException {
      // Sem rede: entra com o que o Auth já sabe.
      return Usuario(nome: u.displayName ?? '', email: u.email ?? '');
    }
  }

  @override
  Future<Usuario> entrar(String email, String senha) => _tratar(() async {
        final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
        return _carregarPerfil(cred.user!);
      });

  @override
  Future<Usuario> criar({required String nome, required String email, required String senha}) => _tratar(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: senha);
        final user = cred.user!;
        final usuario = Usuario(nome: nome, apelido: nome.split(' ').first, email: user.email ?? email.trim());
        await Future.wait([
          user.updateDisplayName(nome),
          _doc(user.uid).set({..._paraMapa(usuario), 'criadoEm': FieldValue.serverTimestamp()}),
        ]);
        await user.sendEmailVerification();
        return usuario;
      });

  @override
  Future<void> recuperarSenha(String email) => _tratar(() async {
        try {
          await _auth.sendPasswordResetEmail(email: email.trim());
        } on FirebaseAuthException catch (e) {
          // Não revelamos se o e-mail tem conta.
          if (e.code != 'user-not-found') rethrow;
        }
      });

  @override
  Future<void> alterarSenha({required String atual, required String nova}) => _tratar(() async {
        final user = _user;
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: atual));
        await user.updatePassword(nova);
      }, senhaAtual: true);

  @override
  Future<bool> salvarPerfil(Usuario usuario) => _tratar(() async {
        final user = _user;
        final novoEmail = usuario.email.trim();
        final mudouEmail = novoEmail.toLowerCase() != (user.email ?? '').toLowerCase();
        if (mudouEmail) await user.verifyBeforeUpdateEmail(novoEmail);
        // O e-mail só muda no perfil depois de confirmado (ver sessaoAtual).
        await Future.wait([
          _doc(user.uid).set(_paraMapa(usuario.copyWith(email: user.email)), SetOptions(merge: true)),
          if (usuario.nome != user.displayName) user.updateDisplayName(usuario.nome),
        ]);
        return mudouEmail;
      });

  @override
  Future<void> sair() => _auth.signOut();

  @override
  Future<void> excluir(String senha) => _tratar(() async {
        final user = _user;
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: senha));
        await _doc(user.uid).delete();
        await user.delete();
      });

  Future<Usuario> _carregarPerfil(User user) async {
    final snap = await _doc(user.uid).get();
    final dados = snap.data();
    final email = user.email ?? '';
    if (dados == null) {
      // Perfil ainda não existe (ex.: falha de rede no cadastro): recria.
      final u = Usuario(nome: user.displayName ?? '', email: email);
      await _doc(user.uid).set(_paraMapa(u), SetOptions(merge: true));
      return u;
    }
    if (dados['email'] != email) await _doc(user.uid).update({'email': email});
    final foto = dados['foto'];
    return Usuario(
      nome: (dados['nome'] as String?) ?? user.displayName ?? '',
      apelido: (dados['apelido'] as String?) ?? '',
      email: email,
      foto: foto is Blob ? foto.bytes : null,
    );
  }

  Map<String, Object?> _paraMapa(Usuario u) => {
        'nome': u.nome,
        'apelido': u.apelido,
        'email': u.email,
        'foto': u.foto == null ? null : Blob(u.foto!),
      };

  /// Converte erros do Firebase em mensagens em linguagem simples.
  Future<T> _tratar<T>(Future<T> Function() fn, {bool senhaAtual = false}) async {
    try {
      return await fn();
    } on FirebaseAuthException catch (e) {
      throw _mensagemAuth(e.code, senhaAtual: senhaAtual);
    } on FirebaseException catch (e) {
      throw ErroConta(e.code == 'unavailable'
          ? 'Sem conexão com a internet. Tente de novo.'
          : 'Não foi possível salvar agora. Tente de novo em instantes.');
    }
  }

  ErroConta _mensagemAuth(String code, {bool senhaAtual = false}) {
    return switch (code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' => ErroConta(
          senhaAtual ? 'A senha atual está incorreta.' : 'E-mail ou senha incorretos.',
        ),
      'invalid-email' => const ErroConta('Digite um e-mail válido, como nome@exemplo.com.'),
      'email-already-in-use' => const ErroConta('Já existe uma conta com este e-mail. Tente entrar.'),
      'weak-password' || 'password-does-not-meet-requirements' =>
        const ErroConta('A senha é muito fraca. Siga os requisitos indicados.'),
      'user-disabled' => const ErroConta('Esta conta foi desativada. Fale com o suporte.'),
      'too-many-requests' =>
        const ErroConta('Muitas tentativas seguidas. Por segurança, aguarde alguns minutos e tente de novo.'),
      'network-request-failed' => const ErroConta('Sem conexão com a internet. Tente de novo.'),
      'requires-recent-login' =>
        const ErroConta('Por segurança, confirme sua senha para continuar.', precisaSenha: true),
      'operation-not-allowed' =>
        const ErroConta('O login por e-mail ainda não foi ativado no Firebase.'),
      _ => const ErroConta('Algo deu errado. Tente de novo em instantes.'),
    };
  }
}
