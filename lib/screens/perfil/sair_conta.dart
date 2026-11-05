import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/cuida_tema.dart';
import '../../widgets/widgets.dart';
import '../login_screen.dart';

/// Encerra a sessão e volta ao Login, limpando toda a pilha de telas.
void encerrarSessao(BuildContext context) {
  final estado = AppScope.read(context);
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
  estado.sair();
}

/// Confirmação "Sair da conta?" em folha inferior.
Future<void> mostrarSairConta(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    barrierColor: CuidaCores.tintaEscura.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (folha) {
      final t = folha.tema;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: CuidaCores.borda, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(header: true, child: Text('Sair da conta?', style: t.serif(26))),
              const SizedBox(height: 14),
              Text(
                'Para voltar, você vai precisar do seu e-mail e da sua senha. Preferências e conteúdos salvos continuam guardados.',
                style: t.sans(15, lh: 23, cor: t.mut),
              ),
              const SizedBox(height: 20),
              BotaoPrimario('Sair', cor: CuidaCores.erro, onPressed: () {
                Navigator.pop(folha);
                encerrarSessao(context);
              }),
              const SizedBox(height: 10),
              BotaoSecundario('Cancelar', onPressed: () => Navigator.pop(folha)),
            ],
          ),
        ),
      );
    },
  );
}
