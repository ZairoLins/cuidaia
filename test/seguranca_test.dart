import 'package:cuidaia/data/assistente.dart';
import 'package:cuidaia/data/assistente_gemini.dart';
import 'package:cuidaia/data/conteudos.dart';
import 'package:cuidaia/data/instrucoes_assistente.dart';
import 'package:cuidaia/services/conta.dart';
import 'package:cuidaia/services/links.dart';
import 'package:cuidaia/state/chat_controller.dart';
import 'package:cuidaia/widgets/campos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Links', () {
    test('só abre páginas seguras, o discador e o mapa', () {
      expect(linkPermitido('https://www.gov.br/saude/pt-br'), isTrue);
      expect(linkPermitido('tel:192'), isTrue);
      expect(linkPermitido('geo:0,0?q=UPA'), isTrue);

      expect(linkPermitido('http://exemplo.com'), isFalse);
      expect(linkPermitido('javascript:alert(1)'), isFalse);
      expect(linkPermitido('file:///etc/passwd'), isFalse);
      expect(linkPermitido('intent://abrir#Intent;end'), isFalse);
      expect(linkPermitido(''), isFalse);
    });

    test('todas as fontes e referências do app usam endereço permitido', () {
      final urls = [
        for (final f in fontesOficiais.values) f.url,
        for (final r in referenciasAprenda) r.url,
        for (final a in artigos.values)
          for (final r in a.refs) r.url,
      ];
      expect(urls, isNotEmpty);
      for (final url in urls) {
        expect(linkPermitido(url), isTrue, reason: url);
      }
    });
  });

  group('Limites de entrada', () {
    test('pergunta maior que o limite é cortada antes de seguir', () {
      final chat = ChatController(assistente: const AssistenteLocal(atraso: Duration.zero));
      chat.perguntar('a' * (limiteCaracteresPergunta + 500));
      final enviada = chat.mensagens.whereType<MsgUsuario>().single;
      expect(enviada.texto.length, limiteCaracteresPergunta);
      chat.dispose();
    });

    testWidgets('campo com limite para de aceitar texto', (tester) async {
      final controle = TextEditingController();
      addTearDown(controle.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuidaCampo(rotulo: 'Nome completo', controller: controle, limite: LimiteCampo.nome),
          ),
        ),
      );
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.inputFormatters!.whereType<LengthLimitingTextInputFormatter>().single.maxLength, LimiteCampo.nome);

      await tester.enterText(find.byType(TextField), 'a' * 300);
      expect(controle.text.length, LimiteCampo.nome);
    });

    test('nome é normalizado e exige sobrenome', () {
      expect(normalizarNome('  Maria   Aparecida \t Souza '), 'Maria Aparecida Souza');
      expect(nomeCompletoValido('Maria Souza'), isTrue);
      expect(nomeCompletoValido('  Maria  '), isFalse);
      expect(nomeCompletoValido(''), isFalse);
    });

    test('resposta da IA com parágrafos demais é cortada no máximo do esquema', () {
      final paragrafos = List.generate(10, (i) => '"Parágrafo $i"').join(',');
      final r = AssistenteGemini.converter('{"paragrafos":[$paragrafos],"fonte":"ras","nivel":"nao_se_aplica"}');
      expect(r.paragrafos.length, maxParagrafosResposta);
    });
  });

  group('Conta', () {
    test('senha atual errada vem marcada, sem depender do texto da mensagem', () async {
      final conta = ContaMemoria(
        contas: {'maria@email.com': ('Senha123!', const Usuario(nome: 'Maria Souza', email: 'maria@email.com'))},
        logado: 'maria@email.com',
      );
      await expectLater(
        conta.alterarSenha(atual: 'errada', nova: 'NovaSenha1'),
        throwsA(isA<ErroConta>().having((e) => e.senhaAtualIncorreta, 'senhaAtualIncorreta', isTrue)),
      );
      await expectLater(
        conta.entrar('maria@email.com', 'errada'),
        throwsA(isA<ErroConta>().having((e) => e.senhaAtualIncorreta, 'senhaAtualIncorreta', isFalse)),
      );
    });
  });
}
