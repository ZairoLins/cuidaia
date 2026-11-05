import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/assistente.dart';

enum FaseChat { livre, enviada, pensando, erro }

final _aleatorio = Random();
String _novoId() => '${DateTime.now().microsecondsSinceEpoch}-${_aleatorio.nextInt(1 << 30)}';

sealed class MensagemChat {
  MensagemChat() : id = _novoId();
  final String id;
}

class MsgUsuario extends MensagemChat {
  MsgUsuario(this.texto);
  final String texto;
  bool falhou = false;
}

class MsgResposta extends MensagemChat {
  MsgResposta(this.resposta);
  final RespostaEducativa resposta;
}

class MsgOpcoes extends MensagemChat {
  String? escolha;
}

class MsgServico extends MensagemChat {
  MsgServico(this.servico, {this.intro = ''});
  final Servico servico;
  final String intro;
}

/// Texto lido em voz alta para uma mensagem do assistente.
String textoParaFala(MensagemChat m) {
  return switch (m) {
    MsgServico(:final servico, :final intro) => [
        intro,
        '${servico.titulo}.',
        servico.texto,
        ...servico.lista,
        servico.extra ?? '',
        'Esta é uma orientação sobre serviços, não um diagnóstico.',
      ].where((t) => t.isNotEmpty).join(' '),
    MsgResposta(:final resposta) => '${resposta.paragrafos.join(' ')} Fonte: ${resposta.fonte}.',
    _ => '',
  };
}

/// Estados da conversa: vazia, enviada, processando, resposta,
/// orientação de atendimento, alerta de emergência e falha de conexão.
class ChatController extends ChangeNotifier {
  ChatController({Assistente? assistente, this.aoNovaResposta})
      : _assistente = assistente ?? const AssistenteLocal();

  final Assistente _assistente;

  /// Chamado quando o assistente entrega uma mensagem (usado para a leitura em voz alta).
  void Function(MensagemChat mensagem)? aoNovaResposta;

  final List<MensagemChat> mensagens = [];
  FaseChat fase = FaseChat.livre;
  final List<Timer> _timers = [];
  bool _encerrado = false;
  int _geracao = 0;

  bool get vazio => mensagens.isEmpty;
  bool get ocupado => fase == FaseChat.enviada || fase == FaseChat.pensando;
  int get totalPerguntas => mensagens.whereType<MsgUsuario>().length;

  List<String> get sugestoesRestantes {
    final feitas = mensagens.whereType<MsgUsuario>().map((m) => m.texto).toSet();
    return perguntasSugeridas.where((q) => !feitas.contains(q)).toList();
  }

  void perguntar(String texto) {
    final t = texto.trim();
    if (t.isEmpty || ocupado) return;
    final msg = MsgUsuario(t);
    mensagens.add(msg);
    fase = FaseChat.enviada;
    _avisar();
    final c = classificar(t);
    _agendar(const Duration(milliseconds: 500), () {
      switch (c) {
        case Classificacao.samu:
          _entregar(
            MsgServico(servicos['samu']!, intro: 'Pelo que você escreveu, pode ser uma situação de risco. Não espere:'),
            const Duration(milliseconds: 700),
          );
        case Classificacao.mental:
          _entregar(
            MsgServico(servicos['mental']!,
                intro: 'Sinto muito que você esteja passando por isso. Você merece apoio agora.'),
            const Duration(milliseconds: 700),
          );
        case Classificacao.orientar:
          _entregar(MsgOpcoes(), const Duration(milliseconds: 900));
        case null:
          _responder(msg);
      }
    });
  }

  void iniciarOrientacao() {
    if (ocupado) return;
    mensagens.add(MsgUsuario('Não sei onde procurar atendimento'));
    fase = FaseChat.enviada;
    _avisar();
    _agendar(const Duration(milliseconds: 400), () => _entregar(MsgOpcoes(), const Duration(milliseconds: 900)));
  }

  void escolher(MsgOpcoes opcoes, OpcaoAtendimento opcao) {
    if (fase == FaseChat.pensando || opcoes.escolha != null) return;
    opcoes.escolha = opcao.chave;
    mensagens.add(MsgUsuario(opcao.titulo));
    _avisar();
    final atraso = Duration(milliseconds: opcao.chave == 'samu' ? 500 : 1200);
    _agendar(const Duration(milliseconds: 300), () => _entregar(MsgServico(servicos[opcao.chave]!), atraso));
  }

  void tentarDeNovo() {
    final falhas = mensagens.whereType<MsgUsuario>().where((m) => m.falhou).toList();
    if (falhas.isEmpty) return;
    final msg = falhas.last;
    msg.falhou = false;
    _responder(msg);
  }

  void limpar() {
    _cancelarTimers();
    _geracao++; // descarta respostas da IA que ainda estavam a caminho
    _assistente.reiniciar();
    mensagens.clear();
    fase = FaseChat.livre;
    _avisar();
  }

  /// Interrompe respostas pendentes (por exemplo, ao sair da conta).
  void encerrar() {
    _encerrado = true;
    _cancelarTimers();
  }

  Future<void> _responder(MsgUsuario pergunta) async {
    final geracao = _geracao;
    fase = FaseChat.pensando;
    _avisar();
    try {
      final resposta = await _assistente.responder(pergunta.texto);
      if (_encerrado || geracao != _geracao) return;
      final msg = MsgResposta(resposta);
      mensagens.add(msg);
      fase = FaseChat.livre;
      _avisar();
      aoNovaResposta?.call(msg);
    } catch (e) {
      if (_encerrado || geracao != _geracao) return;
      debugPrint('Assistente falhou: $e');
      pergunta.falhou = true;
      fase = FaseChat.erro;
      _avisar();
    }
  }

  void _entregar(MensagemChat msg, Duration atraso) {
    fase = FaseChat.pensando;
    _avisar();
    _agendar(atraso, () {
      mensagens.add(msg);
      fase = FaseChat.livre;
      _avisar();
      if (msg is! MsgOpcoes) aoNovaResposta?.call(msg);
    });
  }

  void _agendar(Duration atraso, VoidCallback fn) {
    _timers.add(Timer(atraso, () {
      if (!_encerrado) fn();
    }));
  }

  void _cancelarTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _avisar() {
    if (!_encerrado) notifyListeners();
  }

  @override
  void dispose() {
    encerrar();
    super.dispose();
  }
}
