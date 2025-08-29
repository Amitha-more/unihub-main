import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token'); // Save this token to Firestore for the user
    // Save token to Firestore user document if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      // Handle the message display in your UI
    });

    // Handle FCM messages when app is in background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<bool> isNotificationEnabled(String eventId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return false;

    final notificationEnabledUsers = List<String>.from(eventDoc.data()?['notificationEnabledUsers'] ?? []);
    return notificationEnabledUsers.contains(userId);
  }

  Future<void> scheduleEventNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime eventTime,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    // Add user to notificationEnabledUsers array
    await _firestore.collection('events').doc(eventId).update({
      'notificationEnabledUsers': FieldValue.arrayUnion([userId]),
    });

    // Schedule notification one hour before event
    final notificationTime = eventTime.subtract(const Duration(hours: 1));
    if (notificationTime.isAfter(DateTime.now())) {
      await _firebaseMessaging.sendMessage(
        to: await _firebaseMessaging.getToken() ?? '',
        data: {
          'eventId': eventId,
          'notificationTime': notificationTime.toIso8601String(),
        },
        messageId: 'event_reminder_$eventId',
      );
    }
  }

  Future<void> cancelEventNotification(String eventId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    // Remove user from notificationEnabledUsers array
    await _firestore.collection('events').doc(eventId).update({
      'notificationEnabledUsers': FieldValue.arrayRemove([userId]),
    });
  }
}

// This function must be top-level (outside any class) and static
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
  // Initialize Firebase if needed
  // await Firebase.initializeApp();
} 