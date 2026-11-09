import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notificações locais: agendadas no próprio celular, sem servidor e sem custo.
/// Nunca trazem dados pessoais nem trechos de conversas.
abstract class Lembretes {
  const Lembretes();

  /// `false` onde não dá para agendar (web).
  bool get disponivel;

  /// Pede permissão ao sistema (Android 13+). Retorna se pode notificar.
  Future<bool> pedirPermissao();

  /// Agenda a dica semanal das próximas semanas (substitui as anteriores).
  Future<void> agendarDicas();
  Future<void> cancelarDicas();

  /// Lembra, no dia seguinte, de terminar o artigo que a pessoa começou.
  Future<void> lembrarLeitura({required String topico, required String titulo});
  Future<void> cancelarLeitura();

  /// Ao sair ou excluir a conta.
  Future<void> cancelarTudo();
}

/// Sem notificações (web e testes que não tratam do assunto).
class LembretesDesligados extends Lembretes {
  const LembretesDesligados();

  @override
  bool get disponivel => false;
  @override
  Future<bool> pedirPermissao() async => false;
  @override
  Future<void> agendarDicas() async {}
  @override
  Future<void> cancelarDicas() async {}
  @override
  Future<void> lembrarLeitura({required String topico, required String titulo}) async {}
  @override
  Future<void> cancelarLeitura() async {}
  @override
  Future<void> cancelarTudo() async {}
}

/// Registra o que foi agendado, para os testes.
class LembretesMemoria extends Lembretes {
  LembretesMemoria({this.permitir = true});

  final bool permitir;
  bool dicas = false;
  String? leitura;

  @override
  bool get disponivel => true;
  @override
  Future<bool> pedirPermissao() async => permitir;
  @override
  Future<void> agendarDicas() async => dicas = true;
  @override
  Future<void> cancelarDicas() async => dicas = false;
  @override
  Future<void> lembrarLeitura({required String topico, required String titulo}) async => leitura = topico;
  @override
  Future<void> cancelarLeitura() async => leitura = null;
  @override
  Future<void> cancelarTudo() async {
    dicas = false;
    leitura = null;
  }
}

/// Dicas curtas sobre como usar o SUS, uma por semana, em rodízio.
const dicasSemanais = [
  'A UBS (posto de saúde) é a porta de entrada do SUS: comece por lá para consultas, vacinas e acompanhamento.',
  'Em emergência, como dor no peito ou falta de ar, ligue 192 (SAMU). A ligação é gratuita.',
  'Precisa conversar com alguém? O CVV atende pelo 188, 24 horas por dia, de graça.',
  'A UPA 24h atende urgências como febre alta, cortes e fraturas. Casos sem urgência são melhor acompanhados na UBS.',
  'Consultas com especialistas no SUS começam com um encaminhamento feito na UBS.',
  'As vacinas do Calendário Nacional de Vacinação são gratuitas nas UBS. Leve sua caderneta.',
  'O Cartão Nacional de Saúde (Cartão SUS) pode ser feito na UBS com um documento com foto e o CPF.',
  'Hospitais de alta complexidade cuidam de casos como cirurgias cardíacas e transplantes, com acesso organizado pelo SUS.',
];

/// Ação ao tocar numa notificação: `aprenda` ou `leitura:<topico>`.
typedef AoTocarLembrete = void Function(String payload);

/// Implementação real, com flutter_local_notifications (Android).
class LembretesLocais extends Lembretes {
  LembretesLocais._();

  static final instancia = LembretesLocais._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  static const _idsDicas = 100; // 100..107
  static const _semanasAgendadas = 8;
  static const _idLeitura = 200;

  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes',
      'Lembretes e dicas',
      channelDescription: 'Dica semanal sobre o SUS e lembretes de leitura',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      // O texto não tem dados pessoais, então pode aparecer na tela bloqueada.
      visibility: NotificationVisibility.public,
      // Ícone branco (silhueta do símbolo) tingido com o verde de ação.
      color: Color(0xFF137567),
    ),
  );

  @override
  bool get disponivel => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Prepara o plugin e o fuso horário. Retorna o payload da notificação que
  /// abriu o app, se houver.
  Future<String?> iniciar({required AoTocarLembrete aoTocar}) async {
    if (!disponivel) return null;
    try {
      tzdata.initializeTimeZones();
      final fuso = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(fuso.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notificacao')),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) aoTocar(r.payload!);
      },
    );
    _pronto = true;
    final abertura = await _plugin.getNotificationAppLaunchDetails();
    return abertura?.didNotificationLaunchApp == true ? abertura?.notificationResponse?.payload : null;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> pedirPermissao() async {
    if (!_pronto) return false;
    final android = _android;
    if (android == null) return false;
    if (await android.areNotificationsEnabled() == true) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> agendarDicas() async {
    if (!_pronto) return;
    await cancelarDicas();
    final agora = tz.TZDateTime.now(tz.local);
    // Próxima segunda-feira, 10h.
    var data = tz.TZDateTime(tz.local, agora.year, agora.month, agora.day, 10);
    while (data.weekday != DateTime.monday || !data.isAfter(agora)) {
      data = data.add(const Duration(days: 1));
    }
    // A semana do ano decide a dica, para o rodízio continuar entre reagendamentos.
    final semanaBase = data.difference(tz.TZDateTime(tz.local, data.year)).inDays ~/ 7;
    for (var i = 0; i < _semanasAgendadas; i++) {
      await _plugin.zonedSchedule(
        id: _idsDicas + i,
        scheduledDate: data.add(Duration(days: 7 * i)),
        notificationDetails: _detalhes,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Dica da semana',
        body: dicasSemanais[(semanaBase + i) % dicasSemanais.length],
        payload: 'aprenda',
      );
    }
  }

  @override
  Future<void> cancelarDicas() async {
    if (!_pronto) return;
    for (var i = 0; i < _semanasAgendadas; i++) {
      await _plugin.cancel(id: _idsDicas + i);
    }
  }

  @override
  Future<void> lembrarLeitura({required String topico, required String titulo}) async {
    if (!_pronto) return;
    final agora = tz.TZDateTime.now(tz.local);
    // Dia seguinte, às 18h.
    final data = tz.TZDateTime(tz.local, agora.year, agora.month, agora.day + 1, 18);
    await _plugin.zonedSchedule(
      id: _idLeitura,
      scheduledDate: data,
      notificationDetails: _detalhes,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Continue sua leitura',
      body: titulo,
      payload: 'leitura:$topico',
    );
  }

  @override
  Future<void> cancelarLeitura() async {
    if (_pronto) await _plugin.cancel(id: _idLeitura);
  }

  @override
  Future<void> cancelarTudo() async {
    if (_pronto) await _plugin.cancelAll();
  }
}
