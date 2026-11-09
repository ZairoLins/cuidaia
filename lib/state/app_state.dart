import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/assistente.dart';
import '../services/conta.dart';
import '../services/lembretes.dart';
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
  AppState._(
    this._prefs,
    this._conta,
    this._novoAssistente,
    this._lembretes,
    this._a11y,
    this._notificacoes,
    this._usuario,
  ) {
    _chat = _novoChat();
  }

  static const _chaveA11y = 'cuidaia.a11y';
  static const _chaveNotificacoes = 'cuidaia.notificacoes';
  static const _chaveSalvos = 'cuidaia.salvos';
  static const _chaveProgresso = 'cuidaia.progresso';

  /// Desligadas até a pessoa ligar (e o sistema dar permissão).
  static const notificacoesPadrao = {'dica': false, 'leitura': false};

  /// Lê as preferências do aparelho e a sessão do usuário, se houver.
  static Future<AppState> carregar({
    required Conta conta,
    required Assistente Function() novoAssistente,
    Lembretes lembretes = const LembretesDesligados(),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var a11y = const PreferenciasA11y();
    final notificacoes = Map<String, bool>.of(notificacoesPadrao);
    try {
      final salvo = prefs.getString(_chaveA11y);
      if (salvo != null) a11y = PreferenciasA11y.fromJson(jsonDecode(salvo) as Map<String, dynamic>);
      final notif = prefs.getString(_chaveNotificacoes);
      if (notif != null) {
        (jsonDecode(notif) as Map<String, dynamic>).forEach((k, v) {
          if (notificacoes.containsKey(k)) notificacoes[k] = v == true;
        });
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
    final estado = AppState._(prefs, conta, novoAssistente, lembretes, a11y, notificacoes, usuario);
    estado._salvos.addAll(prefs.getStringList(_chaveSalvos) ?? const []);
    estado._lerProgresso();
    if (usuario != null) estado._reagendar();
    return estado;
  }

  final SharedPreferences _prefs;
  final Conta _conta;
  final Assistente Function() _novoAssistente;
  final Lembretes _lembretes;

  /// `false` na web: lá o navegador não agenda notificações.
  bool get notificacoesDisponiveis => _lembretes.disponivel;

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

  Future<void> entrar(String email, String senha) async => _iniciarSessao(await _conta.entrar(email, senha));

  Future<void> entrarComGoogle() async => _iniciarSessao(await _conta.entrarComGoogle());

  Future<void> criarConta({required String nome, required String email, required String senha}) async =>
      _iniciarSessao(await _conta.criar(nome: nome, email: email, senha: senha));

  void _iniciarSessao(Usuario u) {
    _usuario = u;
    _reagendar();
    notifyListeners();
  }

  /// Refaz a fila da dica semanal (as datas e o rodízio andam com o tempo).
  void _reagendar() {
    if (notificacao('dica')) _lembretes.agendarDicas().catchError((Object e) => debugPrint('Lembretes: $e'));
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
  /// Sem senha (conta Google), a confirmação é feita pelo Google.
  Future<void> excluirConta(String? senha) async {
    await _conta.excluir(senha);
    _salvos.clear();
    _notificacoes
      ..clear()
      ..addAll(notificacoesPadrao);
    _progresso = null;
    await Future.wait([_prefs.remove(_chaveSalvos), _prefs.remove(_chaveNotificacoes), _prefs.remove(_chaveProgresso)]);
    _encerrarLocal();
  }

  /// Encerra a sessão: a próxima entrada começa com uma conversa nova.
  /// Os lembretes param até a pessoa entrar de novo.
  Future<void> sair() async {
    _encerrarLocal();
    await _conta.sair();
  }

  void _encerrarLocal() {
    _lembretes.cancelarTudo().catchError((Object e) => debugPrint('Lembretes: $e'));
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
      'login': usuario.temSenha ? 'e-mail e senha' : 'Google',
      'temFoto': usuario.foto != null,
    },
    'preferenciasAcessibilidade': _a11y.toJson(),
    'notificacoes': _notificacoes,
    'conteudosSalvos': _salvos.toList(),
    'progressoLeitura': ?_progresso?.toJson(),
    'conversaAtual': _chat.mensagens.whereType<MsgUsuario>().map((m) => m.texto).toList(),
  };

  // ---- Preferências ----

  void atualizarA11y(PreferenciasA11y novas) {
    _a11y = novas;
    if (!novas.voz) Voz.instancia.parar();
    _prefs.setString(_chaveA11y, jsonEncode(novas.toJson()));
    notifyListeners();
  }

  /// Liga ou desliga um tipo de notificação. Ao ligar, pede permissão ao
  /// sistema; retorna `false` se ela for negada (o interruptor fica desligado).
  Future<bool> definirNotificacao(String chave, bool valor) async {
    if (valor && !await _lembretes.pedirPermissao()) return false;
    _notificacoes[chave] = valor;
    _prefs.setString(_chaveNotificacoes, jsonEncode(_notificacoes));
    notifyListeners();
    try {
      switch (chave) {
        case 'dica':
          await (valor ? _lembretes.agendarDicas() : _lembretes.cancelarDicas());
        case 'leitura':
          if (!valor) await _lembretes.cancelarLeitura();
      }
    } catch (e) {
      debugPrint('Lembretes: $e');
    }
    return true;
  }

  String? _leituraAberta;
  ProgressoLeitura? _progresso;

  /// Último artigo aberto e ainda não terminado, para o "Continue lendo".
  ProgressoLeitura? get continuarLendo => _progresso == null || _progresso!.concluido ? null : _progresso;

  void _lerProgresso() {
    try {
      final salvo = _prefs.getString(_chaveProgresso);
      if (salvo != null) _progresso = ProgressoLeitura.fromJson(jsonDecode(salvo) as Map<String, dynamic>);
    } catch (_) {
      // Progresso corrompido: o Início sugere um artigo para começar.
    }
  }

  /// Guarda até onde a pessoa rolou o artigo (0 a 1). Só avança, e só grava
  /// a cada 5%, para não escrever no disco a cada quadro da rolagem.
  void registrarProgresso(String topico, double fracao) {
    final atual = _progresso;
    final valor = fracao.clamp(0.0, 1.0);
    if (atual != null && atual.topico == topico && valor < atual.fracao + 0.05 && valor < 1) return;
    if (atual != null && atual.topico == topico && valor <= atual.fracao) return;
    _progresso = ProgressoLeitura(topico, valor);
    _prefs.setString(_chaveProgresso, jsonEncode(_progresso!.toJson()));
    notifyListeners();
  }

  /// A pessoa abriu um artigo: se sair antes do fim, recebe um lembrete amanhã.
  void leituraIniciada({required String topico, required String titulo}) {
    if (_progresso?.topico != topico) registrarProgresso(topico, 0);
    if (!notificacao('leitura')) return;
    _leituraAberta = topico;
    _lembretes.lembrarLeitura(topico: topico, titulo: titulo).catchError((Object e) => debugPrint('Lembretes: $e'));
  }

  /// Chegou ao fim do artigo: o lembrete não é mais necessário.
  void leituraConcluida(String topico) {
    if (_leituraAberta != topico) return;
    _leituraAberta = null;
    _lembretes.cancelarLeitura().catchError((Object e) => debugPrint('Lembretes: $e'));
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
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Lê o estado sem se inscrever (para callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// Até onde a pessoa leu um artigo (fração rolada, de 0 a 1).
class ProgressoLeitura {
  const ProgressoLeitura(this.topico, this.fracao);

  final String topico;
  final double fracao;

  bool get concluido => fracao >= 0.95;

  Map<String, Object> toJson() => {'topico': topico, 'fracao': fracao};

  factory ProgressoLeitura.fromJson(Map<String, dynamic> json) =>
      ProgressoLeitura(json['topico'] as String, (json['fracao'] as num).toDouble());
}
