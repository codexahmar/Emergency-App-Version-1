import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';

import '../UI/screens/location_screen.dart';
import '../main.dart';
import 'serverkey.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/emergencyapp-46566/messages:send';

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'emergency_alerts',
    'Emergency Alerts',
    description: 'Notifications for emergency alerts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Get initial message first
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handleNotificationTap(jsonDecode(response.payload ?? '{}'));
      },
    );

    // Handle background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message.data);
    });

    // Handle terminated state differently
    if (initialMessage != null) {
      // Ensure app is fully initialized before navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (initialMessage.data['type'] == 'emergency') {
          double? latitude =
              double.tryParse(initialMessage.data['latitude'] ?? '');
          double? longitude =
              double.tryParse(initialMessage.data['longitude'] ?? '');

          if (latitude != null && longitude != null) {
            // Use pushReplacement for terminated state to replace the initial route
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => LocationScreen(
                  initialLatitude: latitude,
                  initialLongitude: longitude,
                ),
              ),
            );
          }
        }
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    await requestNotificationPermission();
  }

  static void handleNotificationTap(Map<String, dynamic> data) {
    if (data['type'] == 'emergency') {
      double? latitude = double.tryParse(data['latitude'] ?? '');
      double? longitude = double.tryParse(data['longitude'] ?? '');

      if (latitude != null && longitude != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => LocationScreen(
              initialLatitude: latitude,
              initialLongitude: longitude,
            ),
          ),
        );
      }
    }
  }

  static Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permission");
    } else {
      print("User denied permission");
    }
  }

  static Future<bool> sendEmergencyNotification({
    required String recipientToken,
    required String senderName,
    required String emergencyType,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final serverKey = getServerKey();
      final accessToken = await serverKey.serverToken();
      print(accessToken);

      // final accessToken = "ya29.a0AXeO80RHfyn37uD9n7G2ZMGWvZkfoyMqYkoCRkfWWY0iWwZrwzNnwX6xolh0xVtn9WhXA2J_QBxpOfUtMnGHpkvpjLdnIILPZwbNGvp5bsffK6Wn5Jo_ve9LV2FJF7PlwI_eKVqrEXIHiGf7GGQd21WkruDSHany2Q7XBgV7aCgYKAdoSARESFQHGX2Micm-a37xu7-AFnO425V3nbw0175";
      // print(accessToken);

      if (accessToken.isEmpty) {
        print('Error: Access token is empty');
        return false;
      }

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': recipientToken,
            'notification': {
              'title': '$emergencyType Emergency Alert!',
              'body': '$senderName needs your help!'
            },
            'android': {
              'notification': {
                'channel_id': 'emergency_alerts',
                'sound': 'default',
                'default_sound': true
              },
              'priority': 'high',
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'category': 'EMERGENCY'}
              }
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'type': 'emergency',
              'sender_name': senderName,
              'emergency_type': emergencyType,
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        return true;
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('Error sending notification: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> sendEmergencyNotificationToUser({
    required String recipientDocId,
    required String senderName,
    required String emergencyType,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientDocId)
          .get();

      if (!recipientDoc.exists) {
        print('Recipient document not found');
        return false;
      }

      final recipientData = recipientDoc.data() as Map<String, dynamic>;
      final fcmToken = recipientData['fcmToken'];

      if (fcmToken == null || fcmToken.toString().isEmpty) {
        print('Recipient FCM token is null or empty');
        return false;
      }

      return await sendEmergencyNotification(
        recipientToken: fcmToken,
        senderName: senderName,
        emergencyType: emergencyType,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e, stackTrace) {
      print('Error in sendEmergencyNotificationToUser: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<String> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    return token ?? "";
  }

  static Future<void> debugNotificationFlow({
    required String recipientDocId,
    required String senderName,
  }) async {
    try {
      print(' Starting notification debug...');

      final recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientDocId)
          .get();

      print(' Recipient document exists: ${recipientDoc.exists}');
      if (recipientDoc.exists) {
        final recipientData = recipientDoc.data() as Map<String, dynamic>;
        print(' FCM Token found: ${recipientData['fcmToken'] != null}');
        if (recipientData['fcmToken'] != null) {
          print(' FCM Token: ${recipientData['fcmToken']}');
        }
      }

      final result = await sendEmergencyNotificationToUser(
        recipientDocId: recipientDocId,
        senderName: senderName,
        emergencyType: 'Emergency',
        latitude: 0.0,
        longitude: 0.0,
      );

      print(' Notification send attempt result: $result');
    } catch (e, stackTrace) {
      print(' Debug Error: $e');
      print(' Stack trace: $stackTrace');
    }
  }
}
