import 'package:flutter/material.dart';

import '../theme/cuida_tema.dart';

/// Campo de formulário com rótulo acima, validação e texto de apoio.
class CuidaCampo extends StatelessWidget {
  const CuidaCampo({
    super.key,
    required this.rotulo,
    required this.controller,
    this.dica,
    this.erro,
    this.invalido = false,
    this.valido = false,
    this.oculto = false,
    this.teclado,
    this.autofill,
    this.sufixo,
    this.acaoRotulo,
    this.rotuloOpcional = false,
    this.ajuda,
    this.abaixo,
    this.onChanged,
    this.acaoTeclado,
    this.aoEnviar,
    this.somenteLeitura = false,
  });

  /// Mostra o valor sem permitir edição (ex.: e-mail de quem entra com o Google).
  final bool somenteLeitura;

  final String rotulo;
  final TextEditingController controller;
  final String? dica;
  final String? erro;

  /// Destaca a borda em vermelho mesmo sem mensagem (ex.: requisitos de senha).
  final bool invalido;
  final bool valido;
  final bool oculto;
  final TextInputType? teclado;
  final Iterable<String>? autofill;
  final Widget? sufixo;

  /// Link à direita do rótulo (ex.: "Esqueci minha senha").
  final Widget? acaoRotulo;
  final bool rotuloOpcional;
  final String? ajuda;

  /// Conteúdo extra abaixo do campo (ex.: requisitos de senha).
  final Widget? abaixo;
  final ValueChanged<String>? onChanged;
  final TextInputAction? acaoTeclado;
  final ValueChanged<String>? aoEnviar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final temErro = erro != null || invalido;
    final corBorda = temErro ? CuidaCores.erro : (valido ? CuidaCores.acao : t.borda);
    final largura = temErro ? 1.5 : t.larguraBorda;
    OutlineInputBorder borda(Color cor, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(CuidaRaio.campo),
      borderSide: BorderSide(color: cor, width: w),
    );

    final textoRotulo = Text.rich(
      TextSpan(
        text: rotulo,
        children: [
          if (rotuloOpcional)
            TextSpan(
              text: ' Opcional',
              style: t.sans(14, cor: t.mut),
            ),
        ],
      ),
      style: t.sans(14, peso: FontWeight.w600, cor: CuidaCores.tinta),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: ExcludeSemantics(child: textoRotulo)),
            ?acaoRotulo,
          ],
        ),
        SizedBox(height: acaoRotulo == null ? 6 : 0),
        Semantics(
          label: rotulo,
          readOnly: somenteLeitura,
          child: TextField(
            controller: controller,
            readOnly: somenteLeitura,
            obscureText: oculto,
            enableSuggestions: !oculto,
            autocorrect: !oculto,
            keyboardType: teclado,
            autofillHints: autofill,
            onChanged: onChanged,
            textInputAction: acaoTeclado,
            onSubmitted: aoEnviar,
            style: t.sans(16),
            decoration: InputDecoration(
              hintText: dica,
              hintStyle: t.sans(16, cor: CuidaCores.apoioClaro),
              filled: true,
              fillColor: somenteLeitura ? CuidaCores.fundoSuave : Colors.white,
              // 48 px de altura, como no protótipo.
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: borda(corBorda, largura),
              enabledBorder: borda(corBorda, largura),
              focusedBorder: borda(temErro ? CuidaCores.erro : CuidaCores.acao, 2),
              suffixIcon: sufixo,
              errorText: null,
            ),
          ),
        ),
        if (abaixo != null) ...[const SizedBox(height: 10), abaixo!],
        if (ajuda != null) ...[const SizedBox(height: 6), Text(ajuda!, style: t.sans(13, lh: 19, cor: t.mut))],
        if (erro != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              erro!,
              style: t.sans(13, lh: 18, peso: FontWeight.w600, cor: CuidaCores.erro),
            ),
          ),
        ],
      ],
    );
  }
}

/// Botão de olho para mostrar/ocultar senha.
class BotaoVerSenha extends StatelessWidget {
  const BotaoVerSenha({super.key, required this.visivel, required this.onPressed});

  final bool visivel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: onPressed,
        tooltip: visivel ? 'Ocultar senha' : 'Mostrar senha',
        color: CuidaCores.apoio,
        style: IconButton.styleFrom(shape: CuidaRaio.formaChip),
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: Icon(visivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
      ),
    );
  }
}

class RequisitoSenha {
  const RequisitoSenha(this.texto, this.ok);
  final String texto;
  final bool ok;
}

/// Lista de requisitos da senha: pendente (círculo), ok (check) ou falhou (x).
class RequisitosSenha extends StatelessWidget {
  const RequisitosSenha({super.key, required this.itens, required this.tentou});

  final List<RequisitoSenha> itens;
  final bool tentou;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final r in itens)
          Builder(
            builder: (context) {
              final cor = r.ok ? CuidaCores.acao : (tentou ? CuidaCores.erro : t.mut);
              final icone = r.ok
                  ? Icons.check_rounded
                  : (tentou ? Icons.close_rounded : Icons.radio_button_unchecked_rounded);
              return Semantics(
                label: '${r.texto}: ${r.ok ? 'atendido' : 'pendente'}',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 15, color: cor),
                    const SizedBox(width: 6),
                    Text(
                      r.texto,
                      style: t.sans(13, peso: FontWeight.w500, cor: cor),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Validação de senha usada no cadastro e na troca de senha.
List<RequisitoSenha> requisitosSenha(String senha) => [
  RequisitoSenha('8 caracteres', senha.length >= 8),
  RequisitoSenha('Uma letra', RegExp(r'[A-Za-zÀ-ú]').hasMatch(senha)),
  RequisitoSenha('Um número', RegExp(r'\d').hasMatch(senha)),
];

final _regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
bool emailValido(String email) => _regexEmail.hasMatch(email.trim());
