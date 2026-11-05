import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/assistente.dart';
import '../services/conta.dart';
import '../services/voz.dart';
import 'chat_controller.dart';

export '../services/conta.dart' show ErroConta, Usuario;

enum TamanhoTexto {
  padrao('Padrão', 1),
  grande('Grande', 1.15),
  muito('Muito grande', 1.3);

  const TamanhoTexto(this.rotulo, this.escala);
  final String rotulo;
  final double escala;
}

@immutable
class PreferenciasA11y {
  const PreferenciasA11y({
    this.texto = TamanhoTexto.padrao,
    this.contraste = false,
    this.leitura = false,
    this.movimento = false,
    this.voz = false,
  });

  final TamanhoTexto texto;
  final bool contraste;
  final bool leitura;
  final bool movimento;
  final bool voz;

  PreferenciasA11y copyWith({TamanhoTexto? texto, bool? contraste, bool? leitura, bool? movimento, bool? voz}) {
    return PreferenciasA11y(
      texto: texto ?? this.texto,
      contraste: contraste ?? this.contraste,
      leitura: leitura ?? this.leitura,
      movimento: movimento ?? this.movimento,
      voz: voz ?? this.voz,
    );
  }

  /// Resumo exibido no Perfil, ex.: "Texto grande, alto contraste".
  String get resumo {
    final partes = <String>[
      switch (texto) {
        TamanhoTexto.padrao => 'Texto padrão',
        TamanhoTexto.grande => 'Texto grande',
        TamanhoTexto.muito => 'Texto muito grande',
      },
      if (contraste) 'alto contraste',
      if (leitura) 'fonte facilitada',
      if (movimento) 'menos movimento',
      if (voz) 'leitura em voz alta',
    ];
    return partes.join(', ');
  }

  Map<String, Object> toJson() => {
        'texto': texto.name,
        'contraste': contraste,
        'leitura': leitura,
        'movimento': movimento,
        'voz': voz,
      };

  factory PreferenciasA11y.fromJson(Map<String, dynamic> json) {
    return PreferenciasA11y(
      texto: TamanhoTexto.values.firstWhere((t) => t.name == json['texto'], orElse: () => TamanhoTexto.padrao),
      contraste: json['contraste'] == true,
      leitura: json['leitura'] == true,
      movimento: json['movimento'] == true,
      voz: json['voz'] == true,
    );
  }
}

/// Estado global do app: usuário, preferências, conteúdos salvos e conversa.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this._conta, this._novoAssistente, this._a11y, this._notificacoes, this._usuario) {
    _chat = _novoChat();
  }

  static const _chaveA11y = 'cuidaia.a11y';
  static const _chaveNotificacoes = 'cuidaia.notificacoes';
  static const _chaveSalvos = 'cuidaia.salvos';

  static const notificacoesPadrao = {
    'conteudos': true,
    'leitura': false,
    'novidades': true,
    'resumo': false,
  };

  /// Lê as preferências do aparelho e a sessão do usuário, se houver.
  static Future<AppState> carregar({required Conta conta, required Assistente Function() novoAssistente}) async {
    final prefs = await SharedPreferences.getInstance();
    var a11y = const PreferenciasA11y();
    final notificacoes = Map<String, bool>.of(notificacoesPadrao);
    try {
      final salvo = prefs.getString(_chaveA11y);
      if (salvo != null) a11y = PreferenciasA11y.fromJson(jsonDecode(salvo) as Map<String, dynamic>);
      final notif = prefs.getString(_chaveNotificacoes);
      if (notif != null) {
        (jsonDecode(notif) as Map<String, dynamic>).forEach((k, v) => notificacoes[k] = v == true);
      }
    } catch (_) {
      // Preferências corrompidas: segue com o padrão.
    }
    Usuario? usuario;
    try {
      usuario = await conta.sessaoAtual();
    } catch (_) {
      // Sem sessão válida: abre no login.
    }
    final estado = AppState._(prefs, conta, novoAssistente, a11y, notificacoes, usuario);
    estado._salvos.addAll(prefs.getStringList(_chaveSalvos) ?? const []);
    return estado;
  }

  final SharedPreferences _prefs;
  final Conta _conta;
  final Assistente Function() _novoAssistente;

  PreferenciasA11y _a11y;
  PreferenciasA11y get a11y => _a11y;

  final Map<String, bool> _notificacoes;
  bool notificacao(String chave) => _notificacoes[chave] ?? false;

  final Set<String> _salvos = {};
  bool estaSalvo(String topico) => _salvos.contains(topico);

  Usuario? _usuario;
  bool get logado => _usuario != null;
  Usuario get usuario => _usuario ?? Usuario.vazio;

  late ChatController _chat;
  ChatController get chat => _chat;

  ChatController _novoChat() => ChatController(
        assistente: _novoAssistente(),
        aoNovaResposta: (m) {
          if (_a11y.voz) Voz.instancia.falar(m.id, textoParaFala(m));
        },
      );

  // ---- Conta ----

  Future<void> entrar(String email, String senha) async {
    _usuario = await _conta.entrar(email, senha);
    notifyListeners();
  }

  Future<void> criarConta({required String nome, required String email, required String senha}) async {
    _usuario = await _conta.criar(nome: nome, email: email, senha: senha);
    notifyListeners();
  }

  Future<void> recuperarSenha(String email) => _conta.recuperarSenha(email);

  Future<void> alterarSenha({required String atual, required String nova}) =>
      _conta.alterarSenha(atual: atual, nova: nova);

  /// Salva o perfil. Retorna `true` se um link de troca de e-mail foi enviado;
  /// até a confirmação, o e-mail antigo continua valendo.
  Future<bool> salvarUsuario(Usuario u) async {
    final mudouEmail = await _conta.salvarPerfil(u);
    _usuario = u.copyWith(email: usuario.email);
    notifyListeners();
    return mudouEmail;
  }

  /// Exclui a conta e apaga também o que ficou guardado neste aparelho.
  Future<void> excluirConta(String senha) async {
    await _conta.excluir(senha);
    _salvos.clear();
    _notificacoes
      ..clear()
      ..addAll(notificacoesPadrao);
    await Future.wait([_prefs.remove(_chaveSalvos), _prefs.remove(_chaveNotificacoes)]);
    _encerrarLocal();
  }

  /// Encerra a sessão: a próxima entrada começa com uma conversa nova.
  Future<void> sair() async {
    _encerrarLocal();
    await _conta.sair();
  }

  void _encerrarLocal() {
    Voz.instancia.parar();
    _chat.encerrar();
    _chat = _novoChat();
    _usuario = null;
    notifyListeners();
  }

  /// Cópia dos dados do usuário (portabilidade, LGPD art. 18, V).
  Map<String, Object?> exportarDados() => {
        'geradoEm': DateTime.now().toIso8601String(),
        'perfil': {
          'nome': usuario.nome,
          'apelido': usuario.apelido,
          'email': usuario.email,
          'temFoto': usuario.foto != null,
        },
        'preferenciasAcessibilidade': _a11y.toJson(),
        'notificacoes': _notificacoes,
        'conteudosSalvos': _salvos.toList(),
        'conversaAtual': _chat.mensagens.whereType<MsgUsuario>().map((m) => m.texto).toList(),
      };

  // ---- Preferências ----

  void atualizarA11y(PreferenciasA11y novas) {
    _a11y = novas;
    if (!novas.voz) Voz.instancia.parar();
    _prefs.setString(_chaveA11y, jsonEncode(novas.toJson()));
    notifyListeners();
  }

  void definirNotificacao(String chave, bool valor) {
    _notificacoes[chave] = valor;
    _prefs.setString(_chaveNotificacoes, jsonEncode(_notificacoes));
    notifyListeners();
  }

  void alternarSalvo(String topico) {
    if (!_salvos.remove(topico)) _salvos.add(topico);
    _prefs.setStringList(_chaveSalvos, _salvos.toList());
    notifyListeners();
  }

  void apagarHistorico() {
    _chat.limpar();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState estado, required super.child}) : super(notifier: estado);

  /// Lê o estado e reconstrói o widget quando ele muda.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Lê o estado sem se inscrever (para callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
