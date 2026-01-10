import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../models/models.dart';

class NotificationsService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Rome'));
    } catch (e) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings);
    _initialized = true;
  }

  // 🔔 NOTIFICA IMMEDIATA
  static Future<void> notifyRecurringCreated(Recurring recurring) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'recurring_processed', 'Transazioni Effettuate',
      importance: Importance.max, priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    int notificationId = (recurring.id ?? 0) + 99999;
    await _localNotifications.show(
      notificationId,
      'Transazione Registrata ✅',
      '${recurring.category}: €${recurring.amount.toStringAsFixed(2)}',
      details,
    );
  }

  // ⏰ PROGRAMMAZIONE
  static Future<void> scheduleRecurringNotification(Recurring recurring) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, recurring.dayOfMonth.clamp(1, 28),
      recurring.time.hour, recurring.time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month + 1, recurring.dayOfMonth.clamp(1, 28),
        recurring.time.hour, recurring.time.minute,
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'recurring_schedule', 'Scadenze Ricorrenti',
      importance: Importance.high, priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.zonedSchedule(
      recurring.id ?? 0,
      '⏰ Scadenza ${recurring.isIncome ? 'Entrata' : 'Uscita'}',
      '${recurring.category}: €${recurring.amount.toStringAsFixed(2)} prevista adesso.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // ✅ FIX: Inizializza prima di cancellare
  static Future<void> cancelRecurringNotification(int id) async {
    await initialize(); // Aggiunto questo
    await _localNotifications.cancel(id);
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    return await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }
  
  static Future<void> notifyMonthlySummary({
    required double income,
    required double expense,
    required double balance,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'monthly_summary', 'Riepilogo Mensile',
      importance: Importance.max, priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      88888,
      '📊 Riepilogo Mensile',
      'Entrate: €${income.toStringAsFixed(0)} | Uscite: €${expense.toStringAsFixed(0)} | Saldo: €${balance.toStringAsFixed(0)}',
      details,
    );
  }
}
