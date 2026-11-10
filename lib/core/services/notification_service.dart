import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  developer.log(
    'FCM background message received: ${message.messageId}',
    name: 'NotificationService',
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    // 1. Request Notification Permissions (Android 13+ & iOS)
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      developer.log(
        'FCM Permission status: ${settings.authorizationStatus}',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log('Error requesting FCM permissions: $e', name: 'NotificationService');
    }

    // 2. Set foreground notification presentation options
    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    // 3. Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'FCM foreground message received: ${message.notification?.title}',
        name: 'NotificationService',
      );
    });

    // 4. Handle notification click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'FCM message opened from background: ${message.data}',
        name: 'NotificationService',
      );
    });

    // 5. Handle notification click when app was completely terminated
    try {
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        developer.log(
          'FCM initial message: ${initialMessage.data}',
          name: 'NotificationService',
        );
      }
    } catch (_) {}

    // 6. Subscribe to general topics so broadcasts can be sent from Firebase Console
    try {
      await _fcm.subscribeToTopic('all');
      await _fcm.subscribeToTopic('books');
      developer.log('Subscribed to topics: all, books', name: 'NotificationService');
    } catch (e) {
      developer.log('Error subscribing to topics: $e', name: 'NotificationService');
    }

    // 7. Fetch and log FCM token
    try {
      _fcmToken = await _fcm.getToken();
      developer.log('FCM Device Token: $_fcmToken', name: 'NotificationService');

      _fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        developer.log('FCM Token refreshed: $token', name: 'NotificationService');
      });
    } catch (e) {
      developer.log('Error fetching FCM token: $e', name: 'NotificationService');
    }
  }
}
