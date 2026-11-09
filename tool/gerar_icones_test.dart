// Temporário: gera os PNGs do ícone a partir do símbolo do app.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cuidaia/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _render(WidgetTester tester, Widget w, double lado) async {
  tester.view.physicalSize = Size(lado, lado);
  tester.view.devicePixelRatio = 1;
  final chave = GlobalKey();
  await tester.runAsync(() async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: chave,
          child: SizedBox(width: lado, height: lado, child: w),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
  late ui.Image img;
  await tester.runAsync(() async {
    final rb = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    img = await rb.toImage();
  });
  return img;
}

Future<void> _salvar(WidgetTester tester, ui.Image img, String caminho) async {
  await tester.runAsync(() async {
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File(caminho)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Silhueta branca: só o balão (petróleo) fica opaco; rede e cruz viram recorte.
Future<ui.Image> _silhueta(WidgetTester tester, ui.Image cor) async {
  late ui.Image saida;
  await tester.runAsync(() async {
    final dados = (await cor.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
    final px = Uint8List(dados.length);
    for (var i = 0; i < dados.length; i += 4) {
      final r = dados[i], g = dados[i + 1], b = dados[i + 2], a = dados[i + 3];
      // Petróleo #0F2A36 é escuro; branco e menta são claros.
      final luz = (r * 299 + g * 587 + b * 114) / 1000;
      final escuro = luz < 128 ? 1.0 : 0.0;
      // Borda suave: mistura de petróleo com claro dá luz intermediária.
      final cobertura = luz < 128 ? 1.0 : (luz < 200 ? (200 - luz) / 72 : 0.0);
      px[i] = 255;
      px[i + 1] = 255;
      px[i + 2] = 255;
      px[i + 3] = (a * (escuro > 0 ? 1.0 : cobertura)).round().clamp(0, 255);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(px);
    final desc = ui.ImageDescriptor.raw(
      buffer,
      width: cor.width,
      height: cor.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await desc.instantiateCodec();
    saida = (await codec.getNextFrame()).image;
  });
  return saida;
}

void main() {
  testWidgets('gera ícones', (tester) async {
    const fundo = Color(0xFFE6F2EF);

    // Ícone completo (legado, iOS, web): fundo verde-claro e símbolo grande.
    final completo = await _render(
      tester,
      const ColoredBox(
        color: fundo,
        child: Center(child: CuidaSimbolo(tamanho: 760)),
      ),
      1024,
    );
    await _salvar(tester, completo, 'assets/icone/icone.png');

    // Primeiro plano do ícone adaptativo: cabe na zona segura (66 de 108 dp).
    final frente = await _render(tester, const Center(child: CuidaSimbolo(tamanho: 560)), 1024);
    await _salvar(tester, frente, 'assets/icone/icone_frente.png');

    // Ícone pequeno da notificação (24 dp, branco com transparência).
    const densidades = {'mdpi': 24.0, 'hdpi': 36.0, 'xhdpi': 48.0, 'xxhdpi': 72.0, 'xxxhdpi': 96.0};
    for (final MapEntry(key: d, value: lado) in densidades.entries) {
      final cor = await _render(tester, Center(child: CuidaSimbolo(tamanho: lado * 22 / 24)), lado);
      final branco = await _silhueta(tester, cor);
      await _salvar(tester, branco, 'android/app/src/main/res/drawable-$d/ic_notificacao.png');
    }
    tester.view.reset();
  });
}
