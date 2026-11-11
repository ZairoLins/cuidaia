import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Únicos tipos de endereço que o app abre: páginas seguras (fontes oficiais,
/// mapa), o discador e o app de mapas. Qualquer outro é recusado.
const esquemasPermitidos = {'https', 'tel', 'geo'};

/// Se [url] é um endereço bem formado de um dos [esquemasPermitidos].
bool linkPermitido(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null && esquemasPermitidos.contains(uri.scheme.toLowerCase());
}

Future<void> abrirLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var ok = false;
  try {
    ok = linkPermitido(url) && await launchUrl(Uri.parse(url.trim()), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger?.showSnackBar(const SnackBar(content: Text('Não foi possível abrir. Tente novamente.')));
  }
}

/// Abre o discador com o número (192 SAMU, 188 CVV).
Future<void> ligar(BuildContext context, String numero) => abrirLink(context, 'tel:$numero');

/// Abre o app de mapas do celular buscando [termo] ao redor da pessoa.
/// Quem usa a localização é o app de mapas; o CuidaIA não pede nem recebe.
Future<void> abrirMapa(BuildContext context, String termo) async {
  final q = Uri.encodeQueryComponent(termo);
  // No Android, "geo:" deixa a pessoa usar o app de mapas que preferir.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      if (await launchUrl(Uri.parse('geo:0,0?q=$q'), mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Sem app que trate "geo:": cai no link do Google Maps.
    }
  }
  if (!context.mounted) return;
  await abrirLink(context, 'https://www.google.com/maps/search/?api=1&query=$q');
}
