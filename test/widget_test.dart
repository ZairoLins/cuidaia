import 'package:cuidaia/app.dart';
import 'package:cuidaia/data/assistente.dart';
import 'package:cuidaia/data/assistente_gemini.dart';
import 'package:cuidaia/services/conta.dart';
import 'package:cuidaia/services/lembretes.dart';
import 'package:cuidaia/state/app_state.dart';
import 'package:cuidaia/state/chat_controller.dart';
import 'package:cuidaia/theme/cuida_tema.dart';
import 'package:cuidaia/widgets/botoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _maria = Usuario(nome: 'Maria Aparecida Souza', apelido: 'Maria', email: 'maria@email.com');

ContaMemoria _contaComMaria({bool logada = false}) =>
    ContaMemoria(contas: {'maria@email.com': ('Senha123!', _maria)}, logado: logada ? 'maria@email.com' : null);

Future<AppState> _estado(Conta conta) => AppState.carregar(
  conta: conta,
  novoAssistente: () => const AssistenteLocal(atraso: Duration.zero),
);

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
      expect(find.text('Ainda não tem conta? Criar conta', findRichText: true), findsOneWidget);

      await tester.enterText(_campo('E-mail'), 'maria@email.com');
      await tester.enterText(_campo('Senha'), 'Senha123!');
      await tester.ensureVisible(find.byType(BotaoPrimario));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BotaoPrimario));
      await tester.pumpAndSettle();

      expect(find.text('Como podemos ajudar?'), findsOneWidget);
      expect(find.text('Olá, Maria'), findsOneWidget);
    });

    testWidgets('senha errada mostra o erro e não entra', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(_contaComMaria())));

      await tester.enterText(_campo('E-mail'), 'maria@email.com');
      await tester.enterText(_campo('Senha'), 'errada');
      await tester.ensureVisible(find.byType(BotaoPrimario));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BotaoPrimario));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('Como podemos ajudar?'), findsNothing);
    });

    testWidgets('campos vazios são validados antes de chamar o servidor', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(_contaComMaria())));
      await tester.ensureVisible(find.byType(BotaoPrimario));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BotaoPrimario));
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

    testWidgets('entrar com o Google cria o perfil e esconde "Alterar senha"', (tester) async {
      const ana = Usuario(nome: 'Ana Lima', apelido: 'Ana', email: 'ana@gmail.com', temSenha: false);
      final estado = await _estado(ContaMemoria(contaGoogle: ana));
      await tester.pumpWidget(CuidaApp(estado: estado));

      await tester.ensureVisible(find.byType(BotaoGoogle));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BotaoGoogle));
      await tester.pumpAndSettle();
      expect(find.text('Olá, Ana'), findsOneWidget);

      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
      expect(find.text('Alterar senha'), findsNothing);
    });

    testWidgets('fechar a janela do Google não mostra erro', (tester) async {
      await tester.pumpWidget(CuidaApp(estado: await _estado(ContaMemoria())));
      await tester.ensureVisible(find.byType(BotaoGoogle));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BotaoGoogle));
      await tester.pumpAndSettle();

      expect(find.text('Ainda não tem conta? Criar conta', findRichText: true), findsOneWidget);
      expect(find.textContaining('Tente'), findsNothing);
    });

    test('conta Google é excluída sem pedir senha', () async {
      const ana = Usuario(nome: 'Ana Lima', email: 'ana@gmail.com', temSenha: false);
      final conta = ContaMemoria(contaGoogle: ana);
      final estado = await _estado(conta);
      await estado.entrarComGoogle();

      await estado.excluirConta(null);
      expect(estado.logado, isFalse);
      expect(await conta.sessaoAtual(), isNull);
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

  group('Notificações', () {
    Future<(AppState, LembretesMemoria)> logado({bool permitir = true}) async {
      final lembretes = LembretesMemoria(permitir: permitir);
      final estado = await AppState.carregar(
        conta: _contaComMaria(logada: true),
        novoAssistente: () => const AssistenteLocal(atraso: Duration.zero),
        lembretes: lembretes,
      );
      return (estado, lembretes);
    }

    test('ligar a dica da semana agenda os lembretes; sair cancela', () async {
      final (estado, lembretes) = await logado();
      expect(await estado.definirNotificacao('dica', true), isTrue);
      expect(lembretes.dicas, isTrue);

      await estado.sair();
      expect(lembretes.dicas, isFalse);
    });

    test('permissão negada deixa o interruptor desligado', () async {
      final (estado, lembretes) = await logado(permitir: false);
      expect(await estado.definirNotificacao('dica', true), isFalse);
      expect(estado.notificacao('dica'), isFalse);
      expect(lembretes.dicas, isFalse);
    });

    test('lembrete de leitura some quando o artigo é lido até o fim', () async {
      final (estado, lembretes) = await logado();
      estado.leituraIniciada(topico: 'primaria', titulo: 'Atenção Primária');
      expect(lembretes.leitura, isNull, reason: 'desligado por padrão');

      await estado.definirNotificacao('leitura', true);
      estado.leituraIniciada(topico: 'primaria', titulo: 'Atenção Primária');
      expect(lembretes.leitura, 'primaria');
      estado.leituraConcluida('primaria');
      await Future<void>.delayed(Duration.zero);
      expect(lembretes.leitura, isNull);
    });
  });

  group('Continue lendo', () {
    test('guarda o artigo aberto e o progresso, e some ao terminar', () async {
      final estado = await _estado(_contaComMaria(logada: true));
      expect(estado.continuarLendo, isNull);

      estado.leituraIniciada(topico: 'primaria', titulo: 'Atenção Primária');
      estado.registrarProgresso('primaria', 0.42);
      expect(estado.continuarLendo?.topico, 'primaria');
      expect(estado.continuarLendo?.fracao, closeTo(0.42, 0.001));

      estado.registrarProgresso('primaria', 0.2);
      expect(estado.continuarLendo?.fracao, closeTo(0.42, 0.001), reason: 'o progresso só avança');

      final reaberto = await _estado(_contaComMaria(logada: true));
      expect(reaberto.continuarLendo?.fracao, closeTo(0.42, 0.001), reason: 'fica salvo no aparelho');

      estado.registrarProgresso('primaria', 1);
      expect(estado.continuarLendo, isNull);
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
      final r = AssistenteGemini.converter(
        '{"paragrafos": ["Texto"], "fonte": "inventada", "oferecerOrientacao": true}',
      );
      expect(r.url, 'https://www.gov.br/saude/pt-br');
      expect(r.oferecerOrientacao, isTrue);
    });

    test('resposta vazia vira erro (o chat oferece tentar de novo)', () {
      expect(() => AssistenteGemini.converter('{"paragrafos": [], "fonte": "ras"}'), throwsFormatException);
      expect(() => AssistenteGemini.converter(null), throwsFormatException);
    });
  });

  testWidgets('quem descreve o que sente recebe o botão do mapa com o tipo de unidade', (tester) async {
    final estado = await AppState.carregar(
      conta: _contaComMaria(logada: true),
      novoAssistente: () => const _AssistenteFixo(
        RespostaEducativa(
          paragrafos: ['Febre baixa há dois dias costuma ser avaliada na UBS.'],
          fonte: 'PNAB',
          url: 'https://www.gov.br/saude',
          nivel: NivelSugerido.primaria,
          justificativa: 'Sintoma leve, sem sinais de alarme.',
        ),
      ),
    );
    await tester.pumpWidget(CuidaApp(estado: estado));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.ancestor(of: find.text('Digite sua dúvida sobre saúde...'), matching: find.byType(TextField)),
      'Estou com febre baixa há dois dias e dor no corpo',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Enviar pergunta'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final botao = find.text('Ver UBS perto de mim');
    await tester.scrollUntilVisible(
      botao,
      200,
      scrollable: find
          .ancestor(of: find.textContaining('Pelo que você contou'), matching: find.byType(Scrollable))
          .first,
    );
    expect(botao, findsOneWidget);
    expect(servicos['samu']!.mapa, isNull, reason: 'com risco à vida, a orientação é ligar 192');
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

class _AssistenteFixo extends Assistente {
  const _AssistenteFixo(this.resposta);
  final RespostaEducativa resposta;

  @override
  Future<RespostaEducativa> responder(String pergunta) async => resposta;
}
