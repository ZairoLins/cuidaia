import 'package:flutter/material.dart';

import '../data/assistente.dart';
import '../services/links.dart';
import '../services/voz.dart';
import '../state/app_state.dart';
import '../state/chat_controller.dart';
import '../theme/cuida_tema.dart';
import '../widgets/widgets.dart';
import 'artigo_screen.dart';
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Semantics(
                          liveRegion: true,
                          label: 'Conversa com o assistente',
                          child: _Conversa(chat: chat),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _Entrada(chat: chat, controller: _rascunho, onEnviar: () => _enviar(chat)),
            ],
          ),
        );
      },
    );
  }
}

/// Barra branca: voltar, símbolo em petróleo, título, "Orienta, não diagnostica" e o 192.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.onVoltar});

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: t.linha, width: t.larguraBorda),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, minHeight: 56),
          child: Row(
            children: [
              BotaoVoltar(onPressed: onVoltar),
              const SizedBox(width: 4),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: CuidaCores.petroleo, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: CuidaCores.menta),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text('Assistente CuidaIA', style: t.sans(15.5, peso: FontWeight.w800)),
                    ),
                    Text(
                      'Orienta, não diagnostica',
                      style: t.sans(12.5, peso: FontWeight.w600, cor: t.mut),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Emergência: ligar 192',
                excludeSemantics: true,
                child: Material(
                  color: CuidaCores.erroFundo,
                  shape: CuidaRaio.formaChip,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => ligar(context, '192'),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.call_outlined, size: 15, color: CuidaCores.erroForte),
                          const SizedBox(width: 6),
                          Text(
                            '192',
                            style: t.sans(13, peso: FontWeight.w800, cor: CuidaCores.erroForte),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
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
      Text('Como posso ajudar?', style: t.titulo(20, lh: 27, tracking: -0.01)),
      if (chat.vazio) _InicioConversa(chat: chat),
      for (final m in chat.mensagens)
        switch (m) {
          MsgUsuario() => _BolhaUsuario(msg: m),
          MsgResposta() => _CartaoResposta(msg: m, chat: chat),
          MsgOpcoes() => _CartaoOpcoes(msg: m, chat: chat),
          MsgServico() => _CartaoServico(msg: m, chat: chat),
        },
      if (chat.fase == FaseChat.pensando) const _Pensando(),
      if (chat.fase == FaseChat.erro) _ErroConexao(onTentar: chat.tentarDeNovo),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < itens.length; i++) ...[if (i > 0) const SizedBox(height: 20), itens[i]],
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
          color: CuidaCores.petroleo,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: chat.iniciarOrientacao,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: CuidaCores.menta, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.location_on_outlined, size: 19, color: CuidaCores.petroleo),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Onde devo ser atendido?',
                      style: t.sans(15, peso: FontWeight.w800, cor: Colors.white),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: CuidaCores.menta),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('PERGUNTAS FREQUENTES', semanticsLabel: 'Perguntas frequentes', style: t.legenda(tamanho: 12.5)),
        ),
        for (final q in chat.sugestoesRestantes)
          InkWell(
            onTap: () => chat.perguntar(q),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.linha)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(q, style: t.sans(15, lh: 21, peso: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: CuidaCores.apoioClaro),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Mensagem do usuário: bolha petróleo, cantos 14/14/4/14.
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: CuidaCores.petroleo,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(msg.texto, style: t.sans(15, lh: 22, cor: Colors.white)),
            ),
            const SizedBox(height: 4),
            msg.falhou
                ? Text(
                    'Não enviada',
                    style: t.sans(12, peso: FontWeight.w700, cor: CuidaCores.erro),
                  )
                : Text(
                    'Enviada',
                    style: t.sans(12, peso: FontWeight.w600, cor: CuidaCores.apoioClaro),
                  ),
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
            foregroundColor: t.mut,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: CuidaRaio.formaChip,
            textStyle: t.sans(13, peso: FontWeight.w700),
          ),
          icon: Icon(ativo ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 17),
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
  const _RotuloIA({this.texto = 'Resposta gerada por IA'});

  final String texto;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Selo(texto, icone: Icons.auto_awesome),
  );
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
      raio: 12,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RotuloIA(),
          for (final p in r.paragrafos) ...[
            const SizedBox(height: 10),
            Text(p, style: t.sans(15, lh: 23, cor: t.corpo)),
          ],
          const SizedBox(height: 10),
          Semantics(
            link: true,
            child: Material(
              color: CuidaCores.fundo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: t.linha),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => abrirLink(context, r.url),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 17, color: CuidaCores.info),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FONTE OFICIAL', semanticsLabel: 'Fonte oficial', style: t.legenda(tamanho: 11.5)),
                            Text(
                              r.fonte,
                              style: t.sans(13.5, lh: 19, peso: FontWeight.w600, cor: CuidaCores.info),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.north_east_rounded, size: 14, color: CuidaCores.info),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (r.oferecerOrientacao)
                BotaoCompacto('Saber onde ser atendido', onPressed: chat.ocupado ? null : chat.iniciarOrientacao),
              _BotaoOuvir(msg: msg, textoParado: 'Ouvir', textoFalando: 'Parar'),
            ],
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
      raio: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ORIENTAÇÃO DE ATENDIMENTO', semanticsLabel: 'Orientação de atendimento', style: t.legenda()),
          const SizedBox(height: 12),
          Text('Qual se parece mais com a sua situação?', style: t.sans(16.5, lh: 23, peso: FontWeight.w800)),
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
          Text('Na dúvida, escolha a mais grave.', style: t.sans(13, lh: 19, cor: t.mut)),
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
    final br = BorderRadius.circular(CuidaRaio.botao);
    return Semantics(
      button: true,
      selected: escolhida,
      enabled: !desativada,
      child: Opacity(
        opacity: desativada && !escolhida ? 0.55 : 1,
        child: Material(
          color: escolhida ? CuidaCores.verde50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: br,
            side: BorderSide(color: escolhida ? CuidaCores.acao : t.borda, width: escolhida ? 1.5 : t.larguraBorda),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: desativada ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Faixa de cor da gravidade (vermelho, laranja, verde…).
                      Container(
                        width: 4,
                        decoration: BoxDecoration(color: opcao.cor, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(opcao.titulo, style: t.sans(14.5, lh: 20, peso: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(opcao.descricao, style: t.sans(13, lh: 18, cor: t.mut)),
                          ],
                        ),
                      ),
                      if (escolhida) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.check_rounded, size: 18, color: CuidaCores.acao),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Serviço indicado: faixa colorida no topo, selo do nível, título, texto e ação.
class _CartaoServico extends StatelessWidget {
  const _CartaoServico({required this.msg, required this.chat});

  final MsgServico msg;
  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final t = context.tema;
    final s = msg.servico;
    final urg = s.urgente;
    final faixa = urg ? CuidaCores.erro : CuidaCores.acao;
    final borda = t.altoContraste ? CuidaCores.tinta : (urg ? CuidaCores.erroLinha : CuidaCores.linha);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borda, width: t.altoContraste ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: faixa),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (msg.sugeridoPelaIA) ...[
                  const _RotuloIA(texto: 'Sugestão gerada por IA'),
                  const SizedBox(height: 10),
                ],
                if (msg.intro.isNotEmpty) ...[
                  Text(
                    msg.intro,
                    style: t.sans(14.5, lh: 22, peso: FontWeight.w600, cor: t.corpo),
                  ),
                  const SizedBox(height: 10),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: Selo(
                    s.nivel,
                    cor: urg ? CuidaCores.erroForte : CuidaCores.acaoEscuro,
                    fundo: urg ? CuidaCores.erroFundo : CuidaCores.verde50,
                    forte: true,
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(header: true, child: Text(s.titulo, style: t.titulo(19, lh: 25, tracking: -0.01))),
                const SizedBox(height: 10),
                if (msg.justificativa != null) ...[
                  Text(
                    'Por quê: ${msg.justificativa}',
                    style: t.sans(14.5, lh: 22, peso: FontWeight.w600, cor: t.corpo),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(s.texto, style: t.sans(15, lh: 23, cor: t.corpo)),
                if (s.lista.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ListaMarcadores(itens: s.lista, cor: faixa, tamanho: 14, lh: 21),
                ],
                if (s.acao != null) ...[
                  const SizedBox(height: 12),
                  BotaoPrimario(
                    s.acao!.texto,
                    icone: Icons.call_outlined,
                    cor: urg ? CuidaCores.erro : CuidaCores.acao,
                    onPressed: () => ligar(context, s.acao!.numero),
                  ),
                ],
                if (s.mapa case final mapa?) ...[
                  SizedBox(height: s.acao != null ? 8 : 12),
                  BotaoSecundario(
                    mapa.rotulo,
                    icone: Icons.map_outlined,
                    onPressed: () => abrirMapa(context, mapa.termo),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Abre o app de mapas do seu celular. O CuidaIA não recebe a sua localização.',
                    style: t.sans(12.5, lh: 18, cor: t.mut),
                  ),
                ],
                if (s.extra != null) ...[
                  const SizedBox(height: 10),
                  Text(s.extra!, style: t.sans(13.5, lh: 20, cor: t.mut)),
                ],
                if (msg.sugeridoPelaIA) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (artigoDoNivel(msg.nivel) case final topico?)
                        BotaoCompacto(
                          'Saber mais sobre este nível',
                          icone: Icons.menu_book_outlined,
                          onPressed: () => abrirArtigo(context, topico),
                        ),
                      BotaoCompacto(
                        'Não é bem isso? Ver outras opções',
                        onPressed: chat.ocupado || msg.outrasOpcoesAbertas ? null : () => chat.verOutrasOpcoes(msg),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.linha)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Não é diagnóstico.',
                          style: t.sans(12, lh: 17, peso: FontWeight.w600, cor: t.mut),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BotaoOuvir(msg: msg),
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

class _Pensando extends StatefulWidget {
  const _Pensando();

  @override
  State<_Pensando> createState() => _PensandoState();
}

class _PensandoState extends State<_Pensando> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

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
      label: 'Buscando resposta',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: t.contornoCartao,
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Opacity(
                      opacity: _opacidade(i),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: CuidaCores.acao, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Buscando resposta…',
            style: t.sans(13, peso: FontWeight.w600, cor: t.mut),
          ),
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
    return Aviso(
      tipo: TipoAviso.erro,
      icone: Icons.wifi_off_rounded,
      titulo: 'Sem conexão.',
      texto: 'Sua pergunta foi salva. Em emergência, ligue 192: a ligação funciona mesmo sem internet.',
      acao: Align(
        alignment: Alignment.centerLeft,
        child: BotaoCompacto('Tentar novamente', icone: Icons.refresh_rounded, destrutivo: true, onPressed: onTentar),
      ),
    );
  }
}

/// Rodapé branco: chips de sugestão e o campo de pergunta com botão de enviar.
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: t.linha, width: t.larguraBorda),
        ),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!chat.vazio) ...[
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChipCuida(
                          'Onde ser atendido?',
                          destaque: true,
                          onPressed: chat.ocupado ? null : chat.iniciarOrientacao,
                        ),
                      ),
                      for (final q in sugestoes)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChipCuida(q, onPressed: chat.ocupado ? null : () => chat.perguntar(q)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.borda, width: t.larguraBorda),
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
                            hintStyle: t.sans(15, cor: CuidaCores.apoioClaro),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: semTexto ? null : onEnviar,
                      tooltip: 'Enviar pergunta',
                      style: IconButton.styleFrom(
                        backgroundColor: CuidaCores.acao,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: CuidaCores.trilho,
                        disabledForegroundColor: CuidaCores.apoioClaro,
                        fixedSize: const Size(40, 40),
                        minimumSize: const Size(40, 40),
                        shape: CuidaRaio.formaChip,
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 19),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
