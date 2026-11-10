import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Lembretes locais opt-in: sem conta, backend ou dados de estudo enviados.
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) return false;
    if (_initialized) return true;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
      );
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> scheduleDaily({required int hour, required int minute}) async {
    if (!await initialize()) return false;
    try {
      var scheduled = tz.TZDateTime(
        tz.local,
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        minute,
      );
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: 7357,
        title: 'Hora de praticar música',
        body:
            'Uma prática curta hoje já ajuda a manter seu ritmo de aprendizado.',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'melodyhub_study',
            'Lembretes de estudo',
            channelDescription: 'Lembretes locais de prática musical',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelDaily() async {
    if (!await initialize()) return;
    await _plugin.cancel(id: 7357);
    for (var id = 7360; id <= 7367; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<bool> scheduleWeekly({
    required int hour,
    required int minute,
    required List<int> dias,
  }) async {
    if (dias.isEmpty || dias.any((dia) => dia < 1 || dia > 7)) return false;
    if (!await initialize()) return false;
    try {
      await cancelDaily();
      final agora = tz.TZDateTime.now(tz.local);
      for (final dia in dias.toSet()) {
        var data = tz.TZDateTime(
          tz.local,
          agora.year,
          agora.month,
          agora.day,
          hour,
          minute,
        );
        while (data.weekday != dia || !data.isAfter(agora)) {
          data = data.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          id: 7360 + dia,
          title: 'Hora de praticar música',
          body:
              'Uma prática curta hoje já ajuda a manter seu ritmo de aprendizado.',
          scheduledDate: data,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'melodyhub_study',
              'Lembretes de estudo',
              channelDescription: 'Lembretes locais de prática musical',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return true;
    } catch (_) {
      await cancelDaily();
      return false;
    }
  }

  Future<bool> showAchievement(String title) async {
    if (!await initialize()) return false;
    try {
      await _plugin.show(
        id: 7358,
        title: 'Nova conquista!',
        body: 'Você desbloqueou: $title',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'melodyhub_achievements',
            'Conquistas',
            channelDescription: 'Conquistas desbloqueadas durante o estudo',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (!await initialize()) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macos != null) {
        return await macos.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
