import 'package:cuidaia/data/assistente.dart';
import 'package:cuidaia/data/assistente_gemini.dart';
import 'package:cuidaia/state/chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _AssistenteFixo extends Assistente {
  const _AssistenteFixo(this.resposta);
  final RespostaEducativa resposta;

  @override
  Future<RespostaEducativa> responder(String pergunta) async => resposta;
}

void main() {
  group('Classificação orientativa (JSON do Gemini)', () {
    test('lê o nível e a justificativa e sugere o card do serviço', () {
      final r = AssistenteGemini.converter(
        '{"paragrafos": ["Texto"], "fonte": "decreto7508", "nivel": "secundaria", '
        '"justificativa": "Consulta com especialista é atenção secundária.", "oferecerOrientacao": true}',
      );
      expect(r.nivel, NivelSugerido.secundaria);
      expect(r.justificativa, 'Consulta com especialista é atenção secundária.');
      expect(r.servicoSugerido?.chave, 'secundaria');
      expect(r.oferecerOrientacao, isFalse, reason: 'o card sugerido já oferece as outras opções');
    });

    test('"nao_se_aplica" não sugere serviço e mantém o botão de orientação', () {
      final r = AssistenteGemini.converter(
        '{"paragrafos": ["Texto"], "fonte": "ras", "nivel": "nao_se_aplica", "justificativa": "x", '
        '"oferecerOrientacao": true}',
      );
      expect(r.servicoSugerido, isNull);
      expect(r.justificativa, isNull);
      expect(r.oferecerOrientacao, isTrue);
    });

    test('nível desconhecido é ignorado', () {
      final r = AssistenteGemini.converter('{"paragrafos": ["Texto"], "fonte": "ras", "nivel": "quaternaria"}');
      expect(r.nivel, isNull);
      expect(r.servicoSugerido, isNull);
    });

    test('cada nível leva a um card; secundária e terciária pedem encaminhamento', () {
      for (final n in NivelSugerido.values.where((n) => n != NivelSugerido.naoSeAplica)) {
        expect(servicoDoNivel(n), isNotNull, reason: n.chave);
      }
      expect(servicoDoNivel(NivelSugerido.secundaria)!.texto, contains('encaminhamento'));
      expect(servicoDoNivel(NivelSugerido.terciaria)!.texto, contains('encaminhamento'));
    });
  });

  group('Triagem', () {
    test('pedido de orientação com descrição da situação vai para a IA', () {
      expect(classificar('Onde devo ir? Estou com febre há três dias e dor no corpo'), isNull);
    });
  });

  testWidgets('Chat mostra o card sugerido pela IA e permite ver outras opções', (tester) async {
    final chat = ChatController(
      assistente: const _AssistenteFixo(
        RespostaEducativa(
          paragrafos: ['Explicação'],
          fonte: 'Decreto',
          url: 'https://example.org',
          nivel: NivelSugerido.terciaria,
          justificativa: 'Tratamento de câncer é de alta complexidade.',
        ),
      ),
    );
    addTearDown(chat.dispose);

    chat.perguntar('Meu pai vai precisar fazer quimioterapia');
    await tester.pump(const Duration(milliseconds: 600));

    final card = chat.mensagens.last as MsgServico;
    expect(chat.mensagens[chat.mensagens.length - 2], isA<MsgResposta>());
    expect(card.sugeridoPelaIA, isTrue);
    expect(card.servico.chave, 'terciaria');
    expect(textoParaFala(card), contains('alta complexidade'));

    chat.verOutrasOpcoes(card);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(chat.mensagens.last, isA<MsgOpcoes>());

    chat.verOutrasOpcoes(card); // segundo toque não repete
    await tester.pump(const Duration(milliseconds: 1000));
    expect(chat.mensagens.whereType<MsgOpcoes>(), hasLength(1));
  });
}
