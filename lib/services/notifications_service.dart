import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../models.dart';

class NotificationsService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
  if (_initialized) return;

  // ✅ INIZIALIZZA TIMEZONE
  tz.initializeTimeZones();
  
  // ✅ IMPOSTA ITALIA (Europe/Rome)
  tz.setLocalLocation(tz.getLocation('Europe/Rome'));

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _localNotifications.initialize(settings);
  _initialized = true;
  
  // ✅ DEBUG: Mostra timezone e ora corrente
  final now = tz.TZDateTime.now(tz.local);
  debugPrint('✅ Notifiche inizializzate - Timezone: ${tz.local.name}');
  debugPrint('⏰ Ora corrente: $now');
}

  // 🔔 NOTIFICA IMMEDIATA per transazione ricorrente creata
  static Future<void> notifyRecurringCreated(Recurring recurring) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'recurring_transactions',
      'Transazioni Ricorrenti',
      channelDescription: 'Notifiche per transazioni ricorrenti create',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final emoji = recurring.isIncome ? '💰' : '💸';
    final type = recurring.isIncome ? 'Entrata' : 'Spesa';

    await _localNotifications.show(
      recurring.id ?? 0,
      '$emoji $type Ricorrente Creata',
      '${recurring.category}: €${recurring.amount.toStringAsFixed(2)}',
      details,
    );

    debugPrint('🔔 Notifica inviata per ${recurring.category}');
  }

  // ⏰ PROGRAMMA NOTIFICA RICORRENTE
  static Future<void> scheduleRecurringNotification(Recurring recurring) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    
    // ✅ Calcola la prossima data valida
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      recurring.dayOfMonth.clamp(1, 28), // Evita errori con giorni > 28
      recurring.time.hour,
      recurring.time.minute,
    );

    // ✅ Se è già passato, sposta al mese prossimo
    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        recurring.dayOfMonth.clamp(1, 28),
        recurring.time.hour,
        recurring.time.minute,
      );
    }

    // Notifica 1 ora prima
    final notificationTime = scheduledDate.subtract(const Duration(hours: 1));

    if (notificationTime.isAfter(now)) {
      const androidDetails = AndroidNotificationDetails(
        'recurring_reminders',
        'Promemoria Ricorrenti',
        channelDescription: 'Promemoria per transazioni ricorrenti programmate',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final emoji = recurring.isIncome ? '💰' : '💸';

      await _localNotifications.zonedSchedule(
        (recurring.id ?? 0) + 10000, // ID diverso per reminder
        '⏰ Promemoria $emoji',
        '${recurring.category}: €${recurring.amount.toStringAsFixed(2)} tra 1 ora',
        notificationTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );

      debugPrint('⏰ Promemoria programmato per $notificationTime');
    }
  }

  // 🗑️ CANCELLA NOTIFICA
  static Future<void> cancelRecurringNotification(int recurringId) async {
    await _localNotifications.cancel(recurringId);
    await _localNotifications.cancel(recurringId + 10000);
    debugPrint('🔕 Notifica cancellata per ID $recurringId');
  }

  // 🔔 RIEPILOGO MENSILE (TEST) - ✅ FIX: +10 secondi
  static Future<void> notifyMonthlySummary({
    required double income,
    required double expense,
    required double balance,
  }) async {
    debugPrint('🔔 [START] Test notifica riepilogo mensile');
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'monthly_summary',
      'Riepilogo Mensile',
      channelDescription: 'Riepilogo mensile entrate e uscite',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final emoji = balance >= 0 ? '📈' : '📉';

    // ✅ CHIAVE: Programma tra 10 secondi (non 2!)
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    try {
      await _localNotifications.zonedSchedule(
        999999,
        '$emoji Riepilogo Mensile',
        'Entrate: €${income.toStringAsFixed(2)} | '
        'Uscite: €${expense.toStringAsFixed(2)} | '
        'Saldo: €${balance.toStringAsFixed(2)}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('🔔 [SUCCESS] Notifica programmata per: $scheduledDate');
      debugPrint('⏰ Attendi 10 secondi per vederla!');
    } catch (e) {
      debugPrint('❌ [ERROR] $e');
    }
  }

  // 🔔 RICHIEDI PERMESSI iOS
  static Future<bool> requestPermissions() async {
    await initialize();
    
    final result = await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    return result ?? true;
  }
}

