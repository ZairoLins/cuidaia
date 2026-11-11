import 'package:cuidaia/app.dart';
import 'package:cuidaia/data/assistente.dart';
import 'package:cuidaia/screens/confirmar_email_screen.dart';
import 'package:cuidaia/services/conta.dart';
import 'package:cuidaia/state/app_state.dart';
import 'package:cuidaia/theme/cuida_tema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _estado(Conta conta) => AppState.carregar(
  conta: conta,
  novoAssistente: () => const AssistenteLocal(atraso: Duration.zero),
);

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.pumpAndSettle();
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CuidaTema.usarGoogleFonts = false;
  });

  group('Confirmação de e-mail', () {
    testWidgets('conta nova só entra no app depois de confirmar o e-mail', (tester) async {
      final conta = ContaMemoria();
      final estado = await _estado(conta);
      await estado.criarConta(nome: 'Ana Lima', email: 'ana@email.com', senha: 'Senha123!');
      expect(estado.logado, isTrue);
      expect(estado.liberado, isFalse);

      await tester.pumpWidget(CuidaApp(estado: estado));
      expect(find.text('Confirme seu e-mail'), findsOneWidget);
      expect(find.text('Como podemos ajudar?'), findsNothing);

      // Sem abrir o link, "Já confirmei" não libera.
      await _tocar(tester, 'Já confirmei');
      expect(find.textContaining('Ainda não recebemos a confirmação'), findsOneWidget);
      expect(find.text('Como podemos ajudar?'), findsNothing);

      conta.confirmarEmail('ana@email.com');
      await _tocar(tester, 'Já confirmei');
      expect(estado.liberado, isTrue);
      expect(find.text('Como podemos ajudar?'), findsOneWidget);
    });

    testWidgets('reenviar o link envia uma vez e espera antes de permitir outro', (tester) async {
      final conta = ContaMemoria();
      final estado = await _estado(conta);
      await estado.criarConta(nome: 'Ana Lima', email: 'ana@email.com', senha: 'Senha123!');
      await tester.pumpWidget(CuidaApp(estado: estado));

      await _tocar(tester, 'Reenviar o link');
      expect(conta.reenviosConfirmacao, 1);
      expect(find.textContaining('Link enviado de novo'), findsOneWidget);

      // Durante a espera, o botão fica desligado.
      await tester.tap(find.text('Reenviar o link'));
      await tester.pumpAndSettle();
      expect(conta.reenviosConfirmacao, 1);

      await tester.pump(ConfirmarEmailScreen.esperaReenvio);
      await _tocar(tester, 'Reenviar o link');
      expect(conta.reenviosConfirmacao, 2);

      // Encerra a espera pendente antes do fim do teste.
      await tester.pump(ConfirmarEmailScreen.esperaReenvio);
    });

    testWidgets('quem não confirmou pode sair e usar outra conta', (tester) async {
      final estado = await _estado(ContaMemoria());
      await estado.criarConta(nome: 'Ana Lima', email: 'ana@email.com', senha: 'Senha123!');
      await tester.pumpWidget(CuidaApp(estado: estado));

      await _tocar(tester, 'Sair e usar outra conta');
      expect(estado.logado, isFalse);
      expect(find.text('Entrar'), findsWidgets);
    });

    test('conta que entra com o Google já vem confirmada', () async {
      final estado = await _estado(
        ContaMemoria(contaGoogle: const Usuario(nome: 'Bia Reis', email: 'bia@gmail.com', temSenha: false)),
      );
      await estado.entrarComGoogle();
      expect(estado.liberado, isTrue);
    });
  });
}
