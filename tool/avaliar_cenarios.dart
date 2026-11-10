// Avaliação da classificação orientativa do CuidaIA (objetivo específico 4 do TCC).
//
// Passa cada cenário pelas mesmas duas camadas do app: a triagem por
// palavras-chave (`classificar`) e, se ela não decidir, o Gemini com a mesma
// instrução, formato de resposta, modelo e temperatura. Grava um CSV com cada
// resposta e imprime o resumo das métricas.
//
// Uso (na raiz do projeto):
//   set GEMINI_API_KEY=<chave do Google AI Studio>        (PowerShell: $env:GEMINI_API_KEY="...")
//   dart run tool/avaliar_cenarios.dart --cenarios avaliacao/cenarios.csv --repeticoes 3
//
// Opções: --cenarios <csv>  --saida <csv>  --repeticoes <n>  --modelo <nome>  --pausa-ms <ms>
//
// O CSV de saída é gravado a cada execução. Se ele já existir, o roteiro retoma
// de onde parou: reaproveita as execuções sem erro e só chama a API para as que
// faltam. Assim uma cota esgotada não perde o que já foi feito, e uma mudança no
// gabarito (`esperado`) recalcula as métricas sem chamar o modelo de novo.
// Erros 429/500/503 são repetidos com espera; se a cota DIÁRIA acabar, o roteiro
// para, salva e pede para rodar de novo depois.
//
// A chave fica só na variável de ambiente. Nunca grave a chave em arquivo do repositório.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cuidaia/data/instrucoes_assistente.dart';
import 'package:cuidaia/data/triagem.dart';

Future<void> main(List<String> args) async {
  final op = _opcoes(args);
  final caminhoCenarios = op['cenarios'] ?? 'avaliacao/cenarios.csv';
  final repeticoes = int.parse(op['repeticoes'] ?? '1');
  final modelo = op['modelo'] ?? modeloPadrao;
  final pausa = Duration(milliseconds: int.parse(op['pausa-ms'] ?? '7000'));
  final caminhoSaida = op['saida'] ?? 'avaliacao/resultados.csv';

  final chave = Platform.environment['GEMINI_API_KEY'];
  if (chave == null || chave.isEmpty) {
    stderr.writeln('Defina a variável de ambiente GEMINI_API_KEY antes de rodar.');
    exitCode = 64;
    return;
  }

  final cenarios = _lerCsv(File(caminhoCenarios).readAsStringSync());
  final cab = cenarios.removeAt(0).map((c) => c.trim()).toList();
  final iId = cab.indexOf('id'), iTexto = cab.indexOf('texto'), iEsperado = cab.indexOf('esperado');
  if (iId < 0 || iTexto < 0 || iEsperado < 0) {
    stderr.writeln('O CSV precisa das colunas id, texto e esperado.');
    exitCode = 65;
    return;
  }
  for (final c in cenarios) {
    final e = c[iEsperado].trim();
    if (e != rotuloEsclarecer && NivelSugerido.daChave(e) == null) {
      stderr.writeln('Cenário ${c[iId]}: nível esperado inválido "${c[iEsperado]}".');
      exitCode = 65;
      return;
    }
  }

  stdout.writeln(
    'Modelo: $modelo · temperatura: $temperaturaAssistente · '
    '${cenarios.length} cenários × $repeticoes repetições',
  );

  final http = HttpClient();
  final linhas = <List<String>>[
    [
      'id',
      'repeticao',
      'texto',
      'esperado',
      'obtido',
      'acertou',
      'camada',
      'justificativa',
      'fonte',
      'resposta',
      'erro',
    ],
  ];
  final resultados = <({String esperado, String obtido})>[];

  // Retomada: execuções sem erro de uma rodada anterior no mesmo arquivo.
  final arquivoSaida = File(caminhoSaida);
  final feitas = <String, List<String>>{};
  if (arquivoSaida.existsSync()) {
    final antigas = _lerCsv(arquivoSaida.readAsStringSync());
    if (antigas.isNotEmpty) {
      final cabA = antigas.removeAt(0).map((c) => c.trim()).toList();
      final aId = cabA.indexOf('id'), aRep = cabA.indexOf('repeticao'), aObt = cabA.indexOf('obtido');
      for (final l in antigas) {
        if (l.length >= linhas.first.length && l[aObt] != 'erro') feitas['${l[aId]}#${l[aRep]}'] = l;
      }
    }
    stdout.writeln('Retomando $caminhoSaida: ${feitas.length} execuções já feitas serão reaproveitadas.');
  }

  var cotaDiariaEsgotada = false;
  externo:
  for (final c in cenarios) {
    for (var r = 1; r <= repeticoes; r++) {
      final texto = c[iTexto].trim();
      final esperado = c[iEsperado].trim();

      final anterior = feitas['${c[iId]}#$r'];
      if (anterior != null) {
        final obtidoAnt = anterior[4];
        final linha = [...anterior.take(linhas.first.length)];
        linha[3] = esperado; // gabarito atual, caso tenha sido revisado
        linha[5] = obtidoAnt == esperado ? 'sim' : 'nao';
        linhas.add(linha);
        resultados.add((esperado: esperado, obtido: obtidoAnt));
        stdout.writeln('${c[iId]}#$r  esperado=$esperado  obtido=$obtidoAnt  (já feito)');
        continue;
      }

      var obtido = '', camada = '', justificativa = '', fonte = '', resposta = '', erro = '';

      switch (classificar(texto)) {
        case Classificacao.samu:
          (obtido, camada) = (NivelSugerido.urgencia.chave, 'palavras-chave (SAMU)');
        case Classificacao.mental:
          (obtido, camada) = (NivelSugerido.psicossocial.chave, 'palavras-chave (CVV/CAPS)');
        case Classificacao.orientar:
          (obtido, camada) = ('sem_classificacao', 'palavras-chave (opções manuais)');
        case null:
          camada = 'IA';
          try {
            final json = await _perguntarComRetentativas(http, chave, modelo, texto);
            obtido = rotuloDaResposta(json);
            justificativa = '${json['justificativa'] ?? ''}';
            fonte = '${json['fonte'] ?? ''}';
            resposta = (json['paragrafos'] as List? ?? const []).join(' ');
          } on _ErroHttp catch (e) {
            obtido = 'erro';
            erro = '$e';
            cotaDiariaEsgotada = e.cotaDiaria;
          } catch (e) {
            obtido = 'erro';
            erro = '$e';
          }
          if (cotaDiariaEsgotada) {
            stdout.writeln('${c[iId]}#$r  cota diária da API esgotada: $erro');
            break externo;
          }
          await Future<void>.delayed(pausa); // respeita o limite por minuto da cota gratuita
      }

      final acertou = obtido == esperado;
      resultados.add((esperado: esperado, obtido: obtido));
      linhas.add([
        c[iId],
        '$r',
        texto,
        esperado,
        obtido,
        acertou ? 'sim' : 'nao',
        camada,
        justificativa,
        fonte,
        resposta,
        erro,
      ]);
      final marca = obtido == 'erro' ? 'FALHA NA API: ${_curto(erro)}' : (acertou ? 'OK' : 'divergente');
      stdout.writeln('${c[iId]}#$r  esperado=$esperado  obtido=$obtido  $marca');
      _gravar(arquivoSaida, linhas, feitas);
    }
  }
  http.close();

  _gravar(arquivoSaida, linhas, feitas);
  stdout.writeln('\nResultados gravados em $caminhoSaida');
  if (cotaDiariaEsgotada) {
    stdout.writeln(
      'A cota diária da Gemini API acabou. Rode o mesmo comando de novo depois que ela renovar: '
      'o roteiro continua de onde parou.',
    );
    exitCode = 75;
  }
  stdout.writeln(_resumo(resultados));
}

/// Grava as execuções desta rodada e mantém as da rodada anterior que ainda
/// não foram revisitadas (quando a rodada para no meio).
void _gravar(File arquivo, List<List<String>> linhas, Map<String, List<String>> feitas) {
  final vistas = linhas.skip(1).map((l) => '${l[0]}#${l[1]}').toSet();
  final restantes = feitas.entries.where((e) => !vistas.contains(e.key)).map((e) => e.value);
  final todas = [...linhas, ...restantes];
  arquivo
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('﻿${todas.map((l) => l.map(_campoCsv).join(',')).join('\r\n')}\r\n');
}

String _curto(String s) => s.length <= 160 ? s : '${s.substring(0, 160)}…';

class _ErroHttp implements Exception {
  _ErroHttp(this.status, String corpo) {
    try {
      final erro = (jsonDecode(corpo) as Map<String, dynamic>)['error'] as Map<String, dynamic>? ?? {};
      resumo = '${erro['status'] ?? ''} ${erro['message'] ?? ''}'.trim();
      for (final d in (erro['details'] as List? ?? const [])) {
        if (d is! Map) continue;
        final tipo = '${d['@type']}';
        if (tipo.endsWith('RetryInfo')) {
          final s = double.tryParse('${d['retryDelay']}'.replaceAll('s', ''));
          if (s != null) espera = Duration(milliseconds: (s * 1000).ceil() + 1000);
        }
        if (tipo.endsWith('QuotaFailure')) {
          for (final v in (d['violations'] as List? ?? const [])) {
            if (v is Map && '${v['quotaId']}'.contains('PerDay')) cotaDiaria = true;
          }
        }
      }
    } catch (_) {
      resumo = _curto(corpo);
    }
  }

  final int status;
  String resumo = '';
  Duration? espera;
  bool cotaDiaria = false;

  bool get temporario => !cotaDiaria && (status == 429 || status == 500 || status == 503);

  @override
  String toString() => 'HTTP $status: $resumo';
}

/// Repete chamadas que falharam por limite por minuto ou instabilidade do
/// servidor, esperando o tempo que a própria API indicar.
Future<Map<String, dynamic>> _perguntarComRetentativas(
  HttpClient http,
  String chave,
  String modelo,
  String texto,
) async {
  const maxTentativas = 5;
  var espera = const Duration(seconds: 15);
  for (var tentativa = 1; ; tentativa++) {
    try {
      return await _perguntar(http, chave, modelo, texto);
    } on _ErroHttp catch (e) {
      if (!e.temporario || tentativa >= maxTentativas) rethrow;
      final atraso = e.espera ?? espera;
      stdout.writeln('    HTTP ${e.status}, nova tentativa em ${atraso.inSeconds}s ($tentativa/$maxTentativas)');
      await Future<void>.delayed(atraso);
    } on TimeoutException {
      if (tentativa >= maxTentativas) rethrow;
      stdout.writeln('    tempo esgotado, nova tentativa em ${espera.inSeconds}s ($tentativa/$maxTentativas)');
      await Future<void>.delayed(espera);
    } on SocketException {
      if (tentativa >= maxTentativas) rethrow;
      stdout.writeln('    falha de conexão, nova tentativa em ${espera.inSeconds}s ($tentativa/$maxTentativas)');
      await Future<void>.delayed(espera);
    }
    espera *= 2;
  }
}

Future<Map<String, dynamic>> _perguntar(HttpClient http, String chave, String modelo, String texto) async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelo:generateContent');
  final corpo = {
    'systemInstruction': {
      'parts': [
        {'text': instrucoesAssistente},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': texto},
        ],
      },
    ],
    'generationConfig': {
      'temperature': temperaturaAssistente,
      'maxOutputTokens': maxTokensAssistente,
      'thinkingConfig': {'thinkingLevel': nivelRaciocinio},
      'responseMimeType': 'application/json',
      'responseSchema': esquemaRespostaRest,
    },
  };
  final req = await http.postUrl(url);
  req.headers
    ..contentType = ContentType.json
    ..set('x-goog-api-key', chave);
  req.add(utf8.encode(jsonEncode(corpo)));
  final res = await req.close().timeout(const Duration(seconds: 60));
  final corpoRes = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) throw _ErroHttp(res.statusCode, corpoRes);
  final dados = jsonDecode(corpoRes) as Map<String, dynamic>;
  final texto0 = dados['candidates'][0]['content']['parts'][0]['text'] as String;
  return jsonDecode(texto0) as Map<String, dynamic>;
}

String _resumo(List<({String esperado, String obtido})> todos) {
  final b = StringBuffer();
  // Falhas de API não são classificações: ficam fora das métricas.
  final rs = todos.where((r) => r.obtido != 'erro').toList();
  final falhas = todos.length - rs.length;
  if (falhas > 0) b.writeln('Execuções com falha na API (fora das métricas): $falhas');
  final total = rs.length;
  final acertos = rs.where((r) => r.esperado == r.obtido).length;
  b.writeln('Acurácia: $acertos/$total (${_pct(acertos, total)})');

  // "esclarecer" não é nível de atenção, mas entra na matriz como resposta esperada.
  final niveis = [...NivelSugerido.values.map((n) => n.chave), rotuloEsclarecer];
  final colunas = [...niveis, 'sem_classificacao', 'invalido'];
  b.writeln('\nMatriz de confusão (linhas = esperado, colunas = obtido):');
  b.writeln(['', ...colunas].map((c) => c.padRight(18)).join());
  for (final e in niveis) {
    b.writeln(
      [
        e,
        ...colunas.map((o) => '${rs.where((r) => r.esperado == e && r.obtido == o).length}'),
      ].map((c) => c.padRight(18)).join(),
    );
  }

  b.writeln('\nPor nível (precisão · revocação):');
  for (final n in niveis) {
    final vp = rs.where((r) => r.esperado == n && r.obtido == n).length;
    final previstos = rs.where((r) => r.obtido == n).length;
    final reais = rs.where((r) => r.esperado == n).length;
    if (reais == 0 && previstos == 0) continue;
    b.writeln('  ${n.padRight(14)} ${_pct(vp, previstos)} · ${_pct(vp, reais)}');
  }

  final urg = rs.where((r) => r.esperado == NivelSugerido.urgencia.chave).toList();
  final sub = urg.where((r) => r.obtido != NivelSugerido.urgencia.chave).length;
  b.writeln('\nSubtriagem (urgência classificada como outro nível): $sub/${urg.length} (${_pct(sub, urg.length)})');
  final naoUrg = rs.where((r) => r.esperado != NivelSugerido.urgencia.chave).toList();
  final sobre = naoUrg.where((r) => r.obtido == NivelSugerido.urgencia.chave).length;
  b.writeln(
    'Sobretriagem (outro nível classificado como urgência): $sobre/${naoUrg.length} (${_pct(sobre, naoUrg.length)})',
  );
  return b.toString();
}

String _pct(int a, int b) => b == 0 ? '—' : '${(100 * a / b).toStringAsFixed(1)}%';

Map<String, String> _opcoes(List<String> args) {
  final m = <String, String>{};
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i].startsWith('--')) m[args[i].substring(2)] = args[++i];
  }
  return m;
}

String _campoCsv(String v) => '"${v.replaceAll('"', '""')}"';

/// CSV simples (RFC 4180): vírgula como separador, aspas para campos com vírgula.
List<List<String>> _lerCsv(String texto) {
  if (texto.startsWith('﻿')) texto = texto.substring(1);
  final linhas = <List<String>>[];
  var campo = StringBuffer();
  var linha = <String>[];
  var aspas = false;
  for (var i = 0; i < texto.length; i++) {
    final ch = texto[i];
    if (aspas) {
      if (ch == '"' && i + 1 < texto.length && texto[i + 1] == '"') {
        campo.write('"');
        i++;
      } else if (ch == '"') {
        aspas = false;
      } else {
        campo.write(ch);
      }
    } else if (ch == '"') {
      aspas = true;
    } else if (ch == ',') {
      linha.add(campo.toString());
      campo = StringBuffer();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < texto.length && texto[i + 1] == '\n') i++;
      linha.add(campo.toString());
      campo = StringBuffer();
      if (linha.any((c) => c.trim().isNotEmpty)) linhas.add(linha);
      linha = <String>[];
    } else {
      campo.write(ch);
    }
  }
  linha.add(campo.toString());
  if (linha.any((c) => c.trim().isNotEmpty)) linhas.add(linha);
  return linhas;
}
