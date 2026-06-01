import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../screens/lens_detay_sayfasi.dart';
import '../screens/regl_detay_sayfasi.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BildirimServisi {
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          Timer(const Duration(milliseconds: 500), () {
            if (payload == 'lens') {
              navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => const LensDetaySayfasi()));
            } else if (payload == 'regl') {
              navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => const ReglDetaySayfasi()));
            }
          });
        }
      },
    );
  }

  static Future<void> anlikSesliBildirimGoster({required int id, required String baslik, required String govde, required String payload}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dengem_id_channel', 'Dengem Bildirimleri',
      channelDescription: 'Kritik Durum ve Hatırlatıcı Sesli Bildirimleri',
      importance: Importance.max, priority: Priority.high,
      playSound: true, visibility: NotificationVisibility.public,
    );
    const NotificationDetails generalDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(id, baslik, govde, generalDetails, payload: payload);
  }
}