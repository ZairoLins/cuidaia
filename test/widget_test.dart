import 'package:cuidaia/app.dart';
import 'package:cuidaia/data/assistente.dart';
import 'package:cuidaia/data/assistente_gemini.dart';
import 'package:cuidaia/services/conta.dart';
import 'package:cuidaia/state/app_state.dart';
import 'package:cuidaia/state/chat_controller.dart';
import 'package:cuidaia/theme/cuida_tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _maria = Usuario(nome: 'Maria Aparecida Souza', apelido: 'Maria', email: 'maria@email.com');

ContaMemoria _contaComMaria({bool logada = false}) => ContaMemoria(
      contas: {'maria@email.com': ('Senha123!', _maria)},
      logado: logada ? 'maria@email.com' : null,
    );

Future<AppState> _estado(Conta conta) =>
    AppState.carregar(conta: conta, novoAssistente: () => const AssistenteLocal(atraso: Duration.zero));

/// Campo de texto pelo rótulo exibido acima dele.
Finder _campo(String rotulo) => find.descendant(
      of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CuidaTema.usarGoogleFonts = false;
  });

  group('Conta', () {
    testWidgets('login com e-mail e senha leva à página inicial', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(_contaComMaria())));
      expect(find.text('Saúde pública, explicada com cuidado.'), findsOneWidget);

      await tester.enterText(_campo('E-mail'), 'maria@email.com');
      await tester.enterText(_campo('Senha'), 'Senha123!');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Como podemos ajudar você hoje?'), findsOneWidget);
      expect(find.text('Olá, Maria'), findsOneWidget);
    });

    testWidgets('senha errada mostra o erro e não entra', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(_contaComMaria())));

      await tester.enterText(_campo('E-mail'), 'maria@email.com');
      await tester.enterText(_campo('Senha'), 'errada');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('Como podemos ajudar você hoje?'), findsNothing);
    });

    testWidgets('campos vazios são validados antes de chamar o servidor', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(_contaComMaria())));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe sua senha.'), findsOneWidget);
    });

    testWidgets('sessão salva abre direto na página inicial', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(_contaComMaria(logada: true))));
      await tester.pumpAndSettle();

      expect(find.text('Olá, Maria'), findsOneWidget);
    });

    testWidgets('esqueci minha senha envia o link para o e-mail digitado', (tester) async {
      final conta = _contaComMaria();
      await tester.pumpWidget(CuidaApp(estado: await _estado(conta)));

      await tester.enterText(_campo('E-mail'), 'maria@email.com');
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();

      expect(conta.emailsRecuperacao, ['maria@email.com']);
      expect(find.textContaining('você vai receber um link'), findsOneWidget);
    });

    test('excluir a conta exige a senha e apaga os dados locais', () async {
      final conta = _contaComMaria(logada: true);
      final estado = await _estado(conta);
      estado.alternarSalvo('ras');

      await expectLater(estado.excluirConta('errada'), throwsA(isA<ErroConta>()));
      expect(estado.logado, isTrue);
      await estado.excluirConta('Senha123!');

      expect(estado.logado, isFalse);
      expect(estado.estaSalvo('ras'), isFalse);
      expect(await conta.sessaoAtual(), isNull);
    });

    test('a cópia dos dados traz perfil e preferências', () async {
      final estado = await _estado(_contaComMaria(logada: true));
      final dados = estado.exportarDados();
      expect((dados['perfil'] as Map)['email'], 'maria@email.com');
      expect(dados, contains('preferenciasAcessibilidade'));
    });
  });

  group('Triagem', () {
    test('situações de risco vão para o SAMU', () {
      expect(classificar('Meu pai está com dor no peito e falta de ar'), Classificacao.samu);
    });

    test('sofrimento emocional vai para apoio em saúde mental', () {
      expect(classificar('não quero mais viver'), Classificacao.mental);
    });

    test('pedido de orientação abre as opções', () {
      expect(classificar('Onde devo procurar atendimento?'), Classificacao.orientar);
    });

    test('perguntas educativas seguem para o assistente', () {
      expect(classificar('O que é a Rede de Atenção à Saúde?'), isNull);
    });
  });

  group('Assistente Gemini', () {
    test('converte o JSON e usa o link da lista de fontes oficiais', () {
      final r = AssistenteGemini.converter(
        '{"paragrafos": ["A UBS é a porta de entrada."], "fonte": "pnab", "oferecerOrientacao": false}',
      );
      expect(r.paragrafos, ['A UBS é a porta de entrada.']);
      expect(r.url, fontesOficiais['pnab']!.url);
    });

    test('fonte desconhecida cai no portal do Ministério da Saúde', () {
      final r = AssistenteGemini.converter('{"paragrafos": ["Texto"], "fonte": "inventada", "oferecerOrientacao": true}');
      expect(r.url, 'https://www.gov.br/saude/pt-br');
      expect(r.oferecerOrientacao, isTrue);
    });

    test('resposta vazia vira erro (o chat oferece tentar de novo)', () {
      expect(() => AssistenteGemini.converter('{"paragrafos": [], "fonte": "ras"}'), throwsFormatException);
      expect(() => AssistenteGemini.converter(null), throwsFormatException);
    });
  });

  testWidgets('Chat responde com fonte oficial', (tester) async {
    final chat = ChatController(assistente: const AssistenteLocal(atraso: Duration(milliseconds: 100)));
    addTearDown(chat.dispose);

    chat.perguntar('O que é a Rede de Atenção à Saúde?');
    expect(chat.fase, FaseChat.enviada);

    await tester.pump(const Duration(milliseconds: 500));
    expect(chat.fase, FaseChat.pensando);

    await tester.pump(const Duration(milliseconds: 200));
    expect(chat.fase, FaseChat.livre);
    final resposta = chat.mensagens.last as MsgResposta;
    expect(resposta.resposta.fonte, contains('4.279/2010'));
    expect(chat.sugestoesRestantes, isNot(contains('O que é a Rede de Atenção à Saúde?')));
  });

  testWidgets('Apagar o histórico descarta a resposta que ainda estava a caminho', (tester) async {
    final chat = ChatController(assistente: const AssistenteLocal(atraso: Duration(milliseconds: 300)));
    addTearDown(chat.dispose);

    chat.perguntar('Pergunta qualquer');
    await tester.pump(const Duration(milliseconds: 600));
    chat.limpar();
    await tester.pump(const Duration(milliseconds: 400));

    expect(chat.mensagens, isEmpty);
    expect(chat.fase, FaseChat.livre);
  });

  testWidgets('Orientação de atendimento indica o serviço escolhido', (tester) async {
    final chat = ChatController();
    addTearDown(chat.dispose);

    chat.iniciarOrientacao();
    await tester.pump(const Duration(milliseconds: 1400));
    final opcoes = chat.mensagens.last as MsgOpcoes;

    chat.escolher(opcoes, opcoesAtendimento.firstWhere((o) => o.chave == 'ubs'));
    await tester.pump(const Duration(milliseconds: 1600));

    final servico = chat.mensagens.last as MsgServico;
    expect(servico.servico.titulo, 'Procure a sua UBS');
    expect(opcoes.escolha, 'ubs');
  });
}
