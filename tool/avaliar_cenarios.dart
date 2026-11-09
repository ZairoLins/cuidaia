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
// A chave fica só na variável de ambiente. Nunca grave a chave em arquivo do repositório.

import 'dart:convert';
import 'dart:io';

import 'package:cuidaia/data/instrucoes_assistente.dart';
import 'package:cuidaia/data/triagem.dart';

Future<void> main(List<String> args) async {
  final op = _opcoes(args);
  final caminhoCenarios = op['cenarios'] ?? 'avaliacao/cenarios.csv';
  final repeticoes = int.parse(op['repeticoes'] ?? '1');
  final modelo = op['modelo'] ?? modeloPadrao;
  final pausa = Duration(milliseconds: int.parse(op['pausa-ms'] ?? '4000'));
  final carimbo = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
  final caminhoSaida = op['saida'] ?? 'avaliacao/resultados_$carimbo.csv';

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
    if (NivelSugerido.daChave(c[iEsperado].trim()) == null) {
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

  for (final c in cenarios) {
    for (var r = 1; r <= repeticoes; r++) {
      final texto = c[iTexto].trim();
      final esperado = c[iEsperado].trim();
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
            final json = await _perguntar(http, chave, modelo, texto);
            obtido = NivelSugerido.daChave(json['nivel'])?.chave ?? 'invalido';
            justificativa = '${json['justificativa'] ?? ''}';
            fonte = '${json['fonte'] ?? ''}';
            resposta = (json['paragrafos'] as List? ?? const []).join(' ');
          } catch (e) {
            obtido = 'erro';
            erro = '$e';
          }
          await Future<void>.delayed(pausa); // respeita o limite da cota gratuita
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
      stdout.writeln('${c[iId]}#$r  esperado=$esperado  obtido=$obtido  ${acertou ? 'OK' : 'ERRO'}');
    }
  }
  http.close();

  File(caminhoSaida)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('﻿${linhas.map((l) => l.map(_campoCsv).join(',')).join('\r\n')}\r\n');
  stdout
    ..writeln('\nResultados gravados em $caminhoSaida')
    ..writeln(_resumo(resultados));
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
  if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}: $corpoRes');
  final dados = jsonDecode(corpoRes) as Map<String, dynamic>;
  final texto0 = dados['candidates'][0]['content']['parts'][0]['text'] as String;
  return jsonDecode(texto0) as Map<String, dynamic>;
}

String _resumo(List<({String esperado, String obtido})> rs) {
  final b = StringBuffer();
  final total = rs.length;
  final acertos = rs.where((r) => r.esperado == r.obtido).length;
  b.writeln('Acurácia: $acertos/$total (${_pct(acertos, total)})');

  final niveis = NivelSugerido.values.map((n) => n.chave).toList();
  final colunas = [...niveis, 'sem_classificacao', 'invalido', 'erro'];
  b.writeln('\nMatriz de confusão (linhas = esperado, colunas = obtido):');
  b.writeln(['', ...colunas].map((c) => c.padRight(14)).join());
  for (final e in niveis) {
    b.writeln(
      [
        e,
        ...colunas.map((o) => '${rs.where((r) => r.esperado == e && r.obtido == o).length}'),
      ].map((c) => c.padRight(14)).join(),
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
