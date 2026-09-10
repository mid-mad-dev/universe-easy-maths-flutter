import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers the device with Firebase Cloud Messaging and keeps the
/// `push_tokens` table in sync with the signed-in Supabase user.
///
/// Push is enabled only when the Android build includes a
/// google-services.json (see android/app/build.gradle.kts). Every call is
/// defensive: a missing Firebase config or a failure degrades to "no push"
/// and never blocks app startup.
class PushService {
  static final PushService instance = PushService._();

  PushService._();

  bool _initialized = false;
  String? _lastSyncedUid;
  String? _lastSyncedToken;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsReady = false;

  SupabaseClient get supabase => Supabase.instance.client;

  String? get uid => supabase.auth.currentUser?.id;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      if (Firebase.apps.isEmpty) {
        // Uses the values bundled by the google-services Gradle plugin.
        // Throws when the build was produced without google-services.json.
        await Firebase.initializeApp();
      }

      await _setupLocalNotifications();

      // Display notifications while the app is in the foreground. When the
      // app is backgrounded or closed, FCM delivers them to the system tray
      // automatically.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Keep the token table in sync with the signed-in user.
      supabase.auth.onAuthStateChange.listen((state) {
        final event = state.event;
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
          registerToken();
        } else if (event == AuthChangeEvent.signedOut) {
          unregisterToken();
        }
      });

      await registerToken();
    } catch (error) {
      debugPrint('PushService: push not available ($error)');
    }
  }

  Future<void> _setupLocalNotifications() async {
    if (_localNotificationsReady) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(settings);
    _localNotificationsReady = true;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _setupLocalNotifications();
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'UNIVERSE EASY MATHS',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'doubts',
            'Doubt notifications',
            channelDescription: 'Updates about your questions and answers',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (error) {
      debugPrint('PushService: foreground display failed ($error)');
    }
  }

  /// Push a fresh FCM token into Supabase for the current user.
  Future<void> registerToken() async {
    if (kIsWeb) return;
    final user = uid;
    if (user == null) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('PushService: notification permission not granted');
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _lastSyncedToken && user == _lastSyncedUid) return;

      await supabase.rpc(
        'register_push_token',
        params: {'p_token': token, 'p_platform': Platform.operatingSystem},
      );
      _lastSyncedToken = token;
      _lastSyncedUid = user;
    } catch (error) {
      debugPrint('PushService: token registration failed ($error)');
    }
  }

  /// Remove this device's token from Supabase on sign-out.
  Future<void> unregisterToken() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await supabase.from('push_tokens').delete().eq('token', token);
    } catch (error) {
      debugPrint('PushService: token removal failed ($error)');
    } finally {
      _lastSyncedToken = null;
      _lastSyncedUid = null;
    }
  }
}
