import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> abrirLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger?.showSnackBar(const SnackBar(content: Text('Não foi possível abrir. Tente novamente.')));
  }
}

/// Abre o discador com o número (192 SAMU, 188 CVV).
Future<void> ligar(BuildContext context, String numero) => abrirLink(context, 'tel:$numero');
