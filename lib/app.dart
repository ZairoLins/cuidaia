import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'theme/cuida_tema.dart';

class CuidaApp extends StatelessWidget {
  const CuidaApp({super.key, required this.estado});

  final AppState estado;

  /// Permite abrir telas de fora da árvore de widgets (ex.: ao tocar numa notificação).
  static final navegador = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Sessão salva pelo Firebase: abre direto no app. Decidido uma vez só;
    // depois, login e logout navegam explicitamente.
    final Widget inicial = estado.logado ? const HomeShell() : const LoginScreen();
    return AppScope(
      estado: estado,
      child: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          final a11y = estado.a11y;
          final tema = CuidaTema(
            altoContraste: a11y.contraste,
            leituraFacil: a11y.leitura,
            movimentoReduzido: a11y.movimento,
          );
          return MaterialApp(
            title: 'CuidaIA',
            navigatorKey: CuidaApp.navegador,
            debugShowCheckedModeBanner: false,
            theme: construirTema(tema),
            // Tamanho do texto (100%, 115%, 130%) somado ao ajuste do sistema,
            // e "reduzir movimento" do app ou do celular.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final escala = (mq.textScaler.scale(1) * a11y.texto.escala).clamp(1.0, 2.0).toDouble();
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(escala),
                  disableAnimations: mq.disableAnimations || a11y.movimento,
                ),
                child: child!,
              );
            },
            home: inicial,
          );
        },
      ),
    );
  }
}
