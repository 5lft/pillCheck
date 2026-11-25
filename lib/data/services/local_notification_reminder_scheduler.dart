import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/dose_time.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/reminder_response.dart';
import '../../domain/services/reminder_scheduler.dart';

/// flutter_local_notifications 기반 복약 알림.
///
/// 알림 id 규칙: medicationId * 100 + timeIndex * 10 + weekday(매일이면 0)
/// → 약 하나당 0~99 범위를 쓰므로 약 단위로 찾아서 취소할 수 있다.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// 단일 구독 스트림: 리스너가 붙기 전 이벤트(앱 콜드 스타트 탭)를 버퍼링한다.
  final _responses = StreamController<ReminderResponse>();

  static const _channelId = 'dose_reminder';
  static const _channelName = '복약 알림';
  static const _categoryId = 'dose_reminder_category';
  static const _actionTaken = 'mark_taken';

  @override
  int get maxPendingReminders => 64;

  @override
  Stream<ReminderResponse> get responses => _responses.stream;

  Future<void> init() async {
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      // 권한은 첫 약 저장 시점에 요청한다 (앱 첫 실행 팝업 X)
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryId,
          actions: [
            DarwinNotificationAction.plain(
              _actionTaken,
              '복용 완료',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    // 앱이 꺼진 상태에서 알림으로 실행된 경우
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
      _handleResponse(response);
    }
  }

  Future<void> _configureLocalTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
  }

  @override
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  @override
  Future<void> schedule(Medication medication) async {
    final medicationId = medication.id!;
    await cancel(medicationId);

    for (var i = 0; i < medication.times.length; i++) {
      final time = medication.times[i];
      if (medication.isEveryDay) {
        await _scheduleRepeating(
          id: _notificationId(medicationId, i, 0),
          medication: medication,
          time: time,
          firstAt: _nextInstanceOf(time),
          repeat: DateTimeComponents.time,
        );
      } else {
        for (final weekday in medication.weekdays) {
          await _scheduleRepeating(
            id: _notificationId(medicationId, i, weekday),
            medication: medication,
            time: time,
            firstAt: _nextInstanceOf(time, weekday: weekday),
            repeat: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    }
  }

  @override
  Future<void> cancel(int medicationId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id ~/ 100 == medicationId) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  Future<void> _scheduleRepeating({
    required int id,
    required Medication medication,
    required DoseTime time,
    required tz.TZDateTime firstAt,
    required DateTimeComponents repeat,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: '💊 ${medication.name} 드실 시간이에요',
      body: medication.memo.isEmpty
          ? '${time.label} 복용 알림'
          : '${time.label} · ${medication.memo}',
      scheduledDate: firstAt,
      notificationDetails: _details,
      // 정확한 알람 권한(SCHEDULE_EXACT_ALARM) 없이 동작하는 모드
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: repeat,
      payload: _encodePayload(medication.id!, time),
    );
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '약 복용 시간을 알려드려요',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          _actionTaken,
          '복용 완료',
          showsUserInterface: true,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: _categoryId),
  );

  int _notificationId(int medicationId, int timeIndex, int weekday) =>
      medicationId * 100 + timeIndex * 10 + weekday;

  tz.TZDateTime _nextInstanceOf(DoseTime time, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (!candidate.isAfter(now) ||
        (weekday != null && candidate.weekday != weekday)) {
      candidate = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day + 1,
        time.hour,
        time.minute,
      );
    }
    return candidate;
  }

  String _encodePayload(int medicationId, DoseTime time) =>
      '$medicationId|${time.totalMinutes}';

  void _handleResponse(NotificationResponse response) {
    final parts = response.payload?.split('|');
    if (parts == null || parts.length != 2) return;
    final medicationId = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (medicationId == null || minutes == null) return;

    _responses.add(
      ReminderResponse(
        medicationId: medicationId,
        time: DoseTime.fromMinutes(minutes),
        action: response.actionId == _actionTaken
            ? ReminderAction.markTaken
            : ReminderAction.open,
      ),
    );
  }
}
