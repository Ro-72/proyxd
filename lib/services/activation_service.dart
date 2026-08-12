import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/laptop_record.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showLocalNotification(LaptopRecord record) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'activation_channel',
      'Activaciones de Laptop',
      channelDescription: 'Notificaciones cuando se detecta una laptop activa',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      record.hashCode,
      '¡Laptop Detectada!',
      'ID: ${record.uid} - ${record.timestamp}',
      details,
    );
  }

  Future<void> sendPushNotification(LaptopRecord record) async {
    try {
      await FirebaseMessaging.instance.sendMessage(
        data: {
          'uid': record.uid,
          'fecha': record.fecha,
          'timestamp': record.timestamp,
          'status': record.status,
        },
      );
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}

class ActivationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription? _subscription;
  final StreamController<LaptopRecord> _activationController = StreamController<LaptopRecord>.broadcast();
  final NotificationService _notificationService = NotificationService();

  Stream<LaptopRecord> get activationStream => _activationController.stream;

  LaptopRecord? _lastActiveRecord;
  DateTime? _lastActivationTime;
  static const Duration cameraActivationDuration = Duration(seconds: 45);

  bool get isCameraActivated {
    if (_lastActivationTime == null) return false;
    return DateTime.now().difference(_lastActivationTime!) < cameraActivationDuration;
  }

  void startMonitoring() {
    _notificationService.initialize();

    FirebaseMessaging.instance.subscribeToTopic('laptop_alerts');

    _subscription = _database.child('usersTest').onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;

      data.forEach((instanceId, recordData) {
        if (recordData is Map) {
          final recordMap = Map<String, dynamic>.from(recordData);

          if (recordMap.containsKey('status') &&
              recordMap['status'] == 'Activo' &&
              recordMap.containsKey('uid') &&
              recordMap.containsKey('fecha') &&
              recordMap.containsKey('timestamp')) {

            final record = LaptopRecord.fromJson(
              instanceId.toString(),
              instanceId.toString(),
              recordMap,
            );

            if (_lastActiveRecord == null ||
                (_lastActiveRecord!.id != record.id &&
                 _isNewerRecord(record, _lastActiveRecord!))) {
              _lastActiveRecord = record;
              _lastActivationTime = DateTime.now();
              _activationController.add(record);
              _notificationService.showLocalNotification(record);
              _notificationService.sendPushNotification(record);
            } else if (isCameraActivated && _lastActiveRecord != null) {
              _activationController.add(_lastActiveRecord!);
            }
          }
        }
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && message.data.containsKey('uid')) {
        _notificationService.showLocalNotification(
          LaptopRecord(
            instanceId: message.data['uid'] ?? '',
            id: message.data['uid'] ?? '',
            uid: message.data['uid'] ?? '',
            fecha: message.data['fecha'] ?? '',
            timestamp: message.data['timestamp'] ?? '',
            status: message.data['status'] ?? 'Activo',
          ),
        );
      }
    });
  }

  bool _isNewerRecord(LaptopRecord newRecord, LaptopRecord oldRecord) {
    final newDateTime = newRecord.getDateTime();
    final oldDateTime = oldRecord.getDateTime();

    if (newDateTime == null || oldDateTime == null) return false;
    return newDateTime.isAfter(oldDateTime);
  }

  void dispose() {
    _subscription?.cancel();
    _activationController.close();
  }
}