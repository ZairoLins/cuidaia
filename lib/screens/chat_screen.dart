import 'package:flutter/material.dart';

import '../data/assistente.dart';
import '../services/links.dart';
import '../services/voz.dart';
import '../state/app_state.dart';
import '../state/chat_controller.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'home_shell.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _rascunho = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rascunho.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _rascunho.dispose();
    super.dispose();
  }

  void _enviar(ChatController chat) {
    final texto = _rascunho.text;
    if (texto.trim().isEmpty || chat.ocupado) return;
    chat.perguntar(texto);
    _rascunho.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = AppScope.of(context).chat;
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Cabecalho(onVoltar: () => HomeShell.of(context).irPara(Aba.inicio)),
              Expanded(
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Semantics(
                    liveRegion: true,
                    label: 'Conversa com o assistente',
                    child: _Conversa(chat: chat),
                  ),
                ),
              ),
              _Entrada(
                chat: chat,
                controller: _rascunho,
                onEnviar: () => _enviar(chat),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.onVoltar});

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.linha, width: t.larguraBorda))),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BotaoVoltar(onPressed: onVoltar),
              const SizedBox(width: 6),
              const CuidaSimbolo(tamanho: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Assistente CuidaIA', style: t.sans(16, peso: FontWeight.w600, cor: CuidaCores.azul)),
                    ),
                    Text('Orientação e informação sobre o SUS', style: t.sans(13, cor: t.mut)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline_rounded, size: 15, color: t.mut),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextoComLinks(
                    estilo: t.sans(12.5, lh: 18, cor: t.mut),
                    trechos: [
                      const TrechoTexto(
                          'Orienta, mas não diagnostica nem substitui profissionais de saúde. Em emergência, ligue '),
                      TrechoTexto('192', onTap: () => ligar(context, '192')),
                      const TrechoTexto('.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Conversa extends StatelessWidget {
  const _Conversa({required this.chat});

  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final itens = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CuidaIA', style: t.sans(12.5, peso: FontWeight.w500, cor: t.mut)),
          const SizedBox(height: 10),
          Text(
            'Olá! Posso explicar como o SUS funciona e orientar você sobre qual serviço procurar.',
            style: t.serif(22, lh: 29),
          ),
          const SizedBox(height: 10),
          Text(
            'Não faço diagnósticos nem indico tratamentos — isso só um profissional de saúde pode fazer.',
            style: t.sans(15, lh: 23, cor: t.mut),
          ),
        ],
      ),
      if (chat.vazio) _InicioConversa(chat: chat),
      for (final m in chat.mensagens)
        switch (m) {
          MsgUsuario() => _BolhaUsuario(msg: m),
          MsgResposta() => _CartaoResposta(msg: m, chat: chat),
          MsgOpcoes() => _CartaoOpcoes(msg: m, chat: chat),
          MsgServico() => _CartaoServico(msg: m),
        },
      if (chat.fase == FaseChat.pensando) const _Pensando(),
      if (chat.fase == FaseChat.erro) _ErroConexao(onTentar: chat.tentarDeNovo),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < itens.length; i++) ...[if (i > 0) const SizedBox(height: 22), itens[i]],
      ],
    );
  }
}

class _InicioConversa extends StatelessWidget {
  const _InicioConversa({required this.chat});

  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: CuidaCores.azul,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: chat.iniciarOrientacao,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: CuidaCores.verde, shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_outlined, size: 20, color: CuidaCores.tintaEscura),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Não sei onde procurar atendimento',
                            style: t.sans(15.5, peso: FontWeight.w600, cor: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Responda uma pergunta e indico o serviço mais adequado',
                            style: t.sans(13, lh: 18, cor: CuidaCores.sobreAzul)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('Ou pergunte sobre o SUS', style: t.sans(14, peso: FontWeight.w600, cor: CuidaCores.azul)),
        ),
        ListaSeparada(
          linhaNoFim: true,
          children: [
            for (final q in chat.sugestoesRestantes)
              InkWell(
                onTap: () => chat.perguntar(q),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(q, style: t.sans(15.5, lh: 22, peso: FontWeight.w500, cor: CuidaCores.azul)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: CuidaCores.verde700),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BolhaUsuario extends StatelessWidget {
  const _BolhaUsuario({required this.msg});

  final MsgUsuario msg;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Align(
      alignment: Alignment.centerRight,
      child: _LarguraMaxima(
        widthFactor: 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: CuidaCores.azul,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(msg.texto, style: t.sans(15.5, lh: 23, cor: Colors.white)),
            ),
            const SizedBox(height: 6),
            msg.falhou
                ? Text('Não enviada', style: t.sans(12, peso: FontWeight.w600, cor: CuidaCores.erro))
                : Text('Enviada', style: t.sans(12, peso: FontWeight.w500, cor: t.mut)),
          ],
        ),
      ),
    );
  }
}

/// Bolha do usuário encolhe para o tamanho do texto, até 82% da largura.
class _LarguraMaxima extends StatelessWidget {
  const _LarguraMaxima({required this.widthFactor, required this.child});

  final double widthFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: c.maxWidth * widthFactor),
        child: child,
      ),
    );
  }
}

class _BotaoOuvir extends StatelessWidget {
  const _BotaoOuvir({required this.msg, this.textoParado = 'Ouvir', this.textoFalando = 'Parar'});

  final MensagemChat msg;
  final String textoParado;
  final String textoFalando;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return ValueListenableBuilder<String?>(
      valueListenable: Voz.instancia.falando,
      builder: (context, falando, _) {
        final ativo = falando == msg.id;
        return TextButton.icon(
            onPressed: () => Voz.instancia.alternar(msg.id, textoParaFala(msg)),
            style: TextButton.styleFrom(
              foregroundColor: CuidaCores.azul,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
              textStyle: t.sans(13.5, peso: FontWeight.w600),
            ),
            icon: Icon(ativo ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 18),
            label: Text(
              ativo ? textoFalando : textoParado,
              semanticsLabel: ativo ? 'Parar leitura em voz alta' : 'Ouvir em voz alta',
            ),
        );
      },
    );
  }
}

class _RotuloIA extends StatelessWidget {
  const _RotuloIA();

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 13, color: CuidaCores.verdeTexto),
        const SizedBox(width: 6),
        Text('Resposta gerada por IA', style: t.sans(12.5, peso: FontWeight.w500, cor: CuidaCores.verdeTexto)),
      ],
    );
  }
}

class _CartaoResposta extends StatelessWidget {
  const _CartaoResposta({required this.msg, required this.chat});

  final MsgResposta msg;
  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final r = msg.resposta;
    return Cartao(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RotuloIA(),
          for (final p in r.paragrafos) ...[
            const SizedBox(height: 10),
            Text(p, style: t.sans(15.5, lh: 24)),
          ],
          const SizedBox(height: 14),
          Semantics(
            link: true,
            child: InkWell(
              onTap: () => abrirLink(context, r.url),
              child: Container(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: t.linha))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.description_outlined, size: 16, color: CuidaCores.azul),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fonte oficial', style: t.sans(12, peso: FontWeight.w600, cor: t.mut)),
                          const SizedBox(height: 1),
                          Text(
                            r.fonte,
                            style: t.sans(13.5,
                                lh: 19,
                                peso: FontWeight.w500,
                                cor: CuidaCores.verde700,
                                decoracao: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (r.oferecerOrientacao) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: BotaoCompacto('Saber onde procurar atendimento',
                  preenchido: true, onPressed: chat.ocupado ? null : chat.iniciarOrientacao),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-8, 0),
              child: _BotaoOuvir(msg: msg, textoParado: 'Ouvir resposta', textoFalando: 'Parar leitura'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoOpcoes extends StatelessWidget {
  const _CartaoOpcoes({required this.msg, required this.chat});

  final MsgOpcoes msg;
  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final escolhida = msg.escolha;
    return Cartao(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Orientação de atendimento', style: t.sans(12.5, peso: FontWeight.w500, cor: CuidaCores.verdeTexto)),
          const SizedBox(height: 12),
          Text('Qual destas situações se parece mais com a sua?', style: t.serif(19, lh: 26, peso: FontWeight.w400)),
          const SizedBox(height: 12),
          for (final op in opcoesAtendimento) ...[
            _BotaoOpcao(
              opcao: op,
              escolhida: escolhida == op.chave,
              desativada: escolhida != null,
              onTap: () => chat.escolher(msg, op),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text('Na dúvida entre duas opções, escolha a mais grave.', style: t.sans(13, lh: 19, cor: t.mut)),
        ],
      ),
    );
  }
}

class _BotaoOpcao extends StatelessWidget {
  const _BotaoOpcao({required this.opcao, required this.escolhida, required this.desativada, required this.onTap});

  final OpcaoAtendimento opcao;
  final bool escolhida;
  final bool desativada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final br = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: escolhida,
      enabled: !desativada,
      child: Opacity(
        opacity: desativada && !escolhida ? 0.55 : 1,
        child: Material(
          color: escolhida ? CuidaCores.verdeSelecao : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: br,
            side: BorderSide(
              color: escolhida ? CuidaCores.verde700 : t.borda,
              width: escolhida ? 1.5 : t.larguraBorda,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: desativada ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: opcao.cor, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opcao.titulo, style: t.sans(15, lh: 21, peso: FontWeight.w600, cor: CuidaCores.azul)),
                          const SizedBox(height: 2),
                          Text(opcao.descricao, style: t.sans(13, lh: 18, cor: t.mut)),
                        ],
                      ),
                    ),
                    if (escolhida) ...[
                      const SizedBox(width: 12),
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_rounded, size: 18, color: CuidaCores.verde700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoServico extends StatelessWidget {
  const _CartaoServico({required this.msg});

  final MsgServico msg;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final s = msg.servico;
    final urg = s.urgente;
    final rotuloCor = urg ? CuidaCores.erro : CuidaCores.verdeTexto;
    final linha = urg ? CuidaCores.erroLinha : t.linha;
    return Cartao(
      cor: urg ? CuidaCores.erroFundo : Colors.white,
      borda: urg ? Border.all(color: CuidaCores.erro, width: 1.5) : null,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (msg.intro.isNotEmpty) ...[
            Text(msg.intro, style: t.sans(15, lh: 23)),
            const SizedBox(height: 10),
          ],
          Text(s.nivel, style: t.sans(12.5, peso: FontWeight.w600, cor: rotuloCor)),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(s.titulo, style: t.serif(23, lh: 28, cor: urg ? CuidaCores.erroTitulo : CuidaCores.azul)),
          ),
          const SizedBox(height: 10),
          Text(s.texto, style: t.sans(15.5, lh: 24)),
          if (s.lista.isNotEmpty) ...[
            const SizedBox(height: 10),
            ListaMarcadores(itens: s.lista, cor: rotuloCor, corLinha: linha, tamanho: 14.5, lh: 21, vertical: 10),
          ],
          if (s.acao != null) ...[
            const SizedBox(height: 10),
            BotaoPrimario(
              s.acao!.texto,
              altura: 52,
              icone: Icons.call_outlined,
              cor: urg ? CuidaCores.erro : CuidaCores.verde700,
              onPressed: () => ligar(context, s.acao!.numero),
            ),
          ],
          if (s.extra != null) ...[
            const SizedBox(height: 10),
            Text(s.extra!, style: t.sans(14, lh: 21, cor: t.mut)),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: linha))),
            child: Row(
              children: [
                Expanded(
                  child: Text('Orientação sobre serviços, não diagnóstico.', style: t.sans(12.5, lh: 18, cor: t.mut)),
                ),
                const SizedBox(width: 8),
                _BotaoOuvir(msg: msg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pensando extends StatefulWidget {
  const _Pensando();

  @override
  State<_Pensando> createState() => _PensandoState();
}

class _PensandoState extends State<_Pensando> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double _opacidade(int i) {
    if (!_anim.isAnimating) return [1.0, 0.6, 0.3][i];
    // Pulso escalonado: cada ponto acende 0,15 s depois do anterior.
    final fase = (_anim.value - i * 0.125) % 1.0;
    final pico = fase < 0.4 ? fase / 0.4 : (fase < 0.8 ? (0.8 - fase) / 0.4 : 0.0);
    return 0.3 + 0.7 * pico.clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      liveRegion: true,
      label: 'Consultando materiais oficiais',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: t.sombra(blur: 20, y: 8, spread: -12, alpha: 0.25),
              border: t.contornoCartao,
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Opacity(
                      opacity: _opacidade(i),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: CuidaCores.verde700, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('Consultando materiais oficiais…', style: t.sans(13, peso: FontWeight.w500, cor: t.mut)),
        ],
      ),
    );
  }
}

class _ErroConexao extends StatelessWidget {
  const _ErroConexao({required this.onTentar});

  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: CuidaCores.erroFundo, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 22, color: CuidaCores.erro),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sem conexão', style: t.sans(15, peso: FontWeight.w600, cor: CuidaCores.erroTitulo)),
                      const SizedBox(height: 3),
                      Text(
                        'Sua pergunta continua salva. Verifique a internet e tente de novo. Em emergência, ligue 192 — a ligação funciona mesmo sem internet.',
                        style: t.sans(14, lh: 21, cor: CuidaCores.erroTexto),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BotaoCompacto('Tentar novamente',
                icone: Icons.refresh_rounded, destrutivo: true, preenchido: true, onPressed: onTentar),
          ],
        ),
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({required this.chat, required this.controller, required this.onEnviar});

  final ChatController chat;
  final TextEditingController controller;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final semTexto = chat.ocupado || controller.text.trim().isEmpty;
    final sugestoes = chat.sugestoesRestantes;

    Widget chip(String texto, VoidCallback onTap, {bool escuro = false}) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: chat.ocupado ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: escuro ? Colors.white : CuidaCores.azul,
              backgroundColor: escuro ? CuidaCores.azul : Colors.white,
              disabledForegroundColor: escuro ? Colors.white70 : t.mut,
              disabledBackgroundColor: escuro ? CuidaCores.azul.withValues(alpha: 0.6) : Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: BorderSide(color: escuro ? CuidaCores.azul : t.borda, width: t.larguraBorda),
              shape: const StadiumBorder(),
              textStyle: t.sans(13.5, peso: FontWeight.w500),
            ),
            child: Text(texto),
          ),
        );

    return Container(
      color: CuidaCores.fundo,
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!chat.vazio) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  chip('Onde procurar atendimento?', chat.iniciarOrientacao, escuro: true),
                  for (final q in sugestoes) chip(q, () => chat.perguntar(q)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.borda, width: t.larguraBorda),
              boxShadow: t.altoContraste
                  ? null
                  : [
                      BoxShadow(
                        color: CuidaCores.azul.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: -12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Sua dúvida',
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onEnviar(),
                      style: t.sans(16),
                      decoration: InputDecoration(
                        hintText: 'Digite sua dúvida sobre saúde...',
                        hintStyle: t.sans(15, cor: CuidaCores.placeholder),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: semTexto ? null : onEnviar,
                  tooltip: 'Enviar pergunta',
                  style: IconButton.styleFrom(
                    backgroundColor: CuidaCores.verde700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: CuidaCores.desativado,
                    disabledForegroundColor: Colors.white,
                    fixedSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
