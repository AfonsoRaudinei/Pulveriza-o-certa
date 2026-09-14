import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/lembretes_config.dart';

/// Notificações locais para lembretes de revisão e backup.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _idRevisao = 1001;
  static const _idBackup = 1002;
  static const _diasLembreteBackup = 30;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> solicitarPermissao() async {
    await ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  /// Reagenda lembretes e devolve config com datas de próximo disparo.
  Future<LembretesConfig> sincronizarLembretes(LembretesConfig config) async {
    await ensureInitialized();
    await cancelarRevisao();
    await cancelarBackup();

    var atualizado = config.copyWith(
      limparProximoRevisao: true,
      limparProximoBackup: true,
    );

    if (config.revisaoAtivo && config.criterio == CriterioLembrete.tempo) {
      final proximo = await _agendarRevisaoPorTempo(config.intervaloDias);
      atualizado = atualizado.copyWith(proximoLembreteRevisao: proximo);
    }

    if (config.lembreteBackupAtivo) {
      final proximo = await _agendarBackup();
      atualizado = atualizado.copyWith(proximoLembreteBackup: proximo);
    }

    return atualizado;
  }

  Future<void> cancelarRevisao() => _plugin.cancel(_idRevisao);

  Future<void> cancelarBackup() => _plugin.cancel(_idBackup);

  Future<void> notificarRevisaoPorUso() async {
    await ensureInitialized();
    await _mostrar(
      id: _idRevisao,
      titulo: 'Hora de revisar os bicos',
      corpo:
          'Você atingiu o número de regulagens configurado. Revise o estado dos bicos.',
    );
  }

  Future<DateTime> _agendarRevisaoPorTempo(int dias) async {
    if (dias <= 0) dias = 1;
    final agendado = tz.TZDateTime.now(tz.local).add(Duration(days: dias));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ponta_verde_lembretes',
        'Lembretes',
        channelDescription: 'Lembretes de revisão e backup do Ponta Verde',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      _idRevisao,
      'Hora de revisar os bicos',
      'Revise periodicamente o estado dos bicos do pulverizador.',
      agendado,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return agendado.toLocal();
  }

  Future<DateTime> _agendarBackup() async {
    final agendado = tz.TZDateTime.now(tz.local).add(
      const Duration(days: _diasLembreteBackup),
    );
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ponta_verde_lembretes',
        'Lembretes',
        channelDescription: 'Lembretes de revisão e backup do Ponta Verde',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      _idBackup,
      'Lembrete de backup',
      'Faça backup dos seus dados do Ponta Verde para não perder suas regulagens.',
      agendado,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return agendado.toLocal();
  }

  Future<void> _mostrar({
    required int id,
    required String titulo,
    required String corpo,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ponta_verde_lembretes',
        'Lembretes',
        channelDescription: 'Lembretes de revisão e backup do Ponta Verde',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, titulo, corpo, details);
  }
}
