import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Ensure this import is present
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    String? clubId,
    required String organizer,
    String? bannerUrl,
    required String venue,
    required List<String> categories,
    required bool isFree,
    required int maxSeats,
    required bool isNotificationEnabled,
    required String createdBy,
    int? maxParticipants,
  }) async {
    try {
      String eventId = _firestore.collection('events').doc().id;
      Timestamp now = Timestamp.now();

      Event newEvent = Event(
        id: eventId,
        title: title,
        description: description,
        dateTime: dateTime,
        location: location,
        clubId: clubId,
        organizer: organizer,
        bannerUrl: bannerUrl,
        venue: venue,
        categories: categories,
        isFree: isFree,
        maxSeats: maxSeats,
        registeredCount: 0,
        status: 'upcoming',
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        registeredUserIds: [],
        registeredUsers: [],
        notificationEnabledUsers: [],
        isNotificationEnabled: isNotificationEnabled,
        maxParticipants: maxParticipants,
      );

      await _firestore
          .collection('events')
          .doc(eventId)
          .set(newEvent.toFirestore());
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    String? clubId,
    required String organizer,
    String? bannerUrl,
    required String venue,
    required List<String> categories,
    required bool isFree,
    required int maxSeats,
    required bool isNotificationEnabled,
    required String createdBy,
    int? maxParticipants,
  }) async {
    try {
      Map<String, dynamic> updatedData = {
        'title': title,
        'description': description,
        'dateTime': Timestamp.fromDate(dateTime),
        'location': location,
        'clubId': clubId,
        'organizer': organizer,
        'bannerUrl': bannerUrl,
        'venue': venue,
        'categories': categories,
        'isFree': isFree,
        'maxSeats': maxSeats,
        'isNotificationEnabled': isNotificationEnabled,
        'maxParticipants': maxParticipants,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('events')
          .doc(eventId)
          .update(updatedData);
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  Stream<List<Event>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .toList());
  }

  Stream<Event> getEventDetails(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => Event.fromFirestore(doc));
  }

  Future<void> registerForEvent(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection('events').doc(eventId);
        final eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final event = Event.fromFirestore(eventDoc);
        if (event.registeredUserIds.contains(userId)) {
          print('User already registered for this event.');
          return;
        }

        if (event.registeredCount >= event.maxSeats && event.maxSeats > 0) {
          throw Exception('Event is full');
        }

        transaction.update(eventRef, {
          'registeredUserIds': FieldValue.arrayUnion([userId]),
          'registeredCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      print('Error registering for event: $e');
      rethrow;
    }
  }

  Future<void> cancelRegistration(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection('events').doc(eventId);
        final eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }
        final event = Event.fromFirestore(eventDoc);

        if (!event.registeredUserIds.contains(userId)) {
           print('User was not registered for this event.');
          return;
        }

        transaction.update(eventRef, {
          'registeredUserIds': FieldValue.arrayRemove([userId]),
          'registeredCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      print('Error cancelling registration: $e');
      rethrow;
    }
  }

  Future<bool> isUserRegistered(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return false;

    final event = Event.fromFirestore(eventDoc);
    return event.registeredUserIds.contains(userId);
  }

  Stream<List<Event>> getRegisteredEvents() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('events')
        .where('registeredUserIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  // <<< THIS IS THE METHOD TO ENSURE IS PRESENT >>>
  Future<void> deleteEvent(String eventId, String? bannerUrl) async {
    try {
      // 1. Delete the event document from Firestore
      await _firestore.collection('events').doc(eventId).delete();
      print('Event $eventId deleted successfully from Firestore.');

      // 2. Delete the banner image from Firebase Storage, if a URL exists
      if (bannerUrl != null && bannerUrl.isNotEmpty) {
        try {
          Reference storageRef = FirebaseStorage.instance.refFromURL(bannerUrl);
          await storageRef.delete();
          print('Successfully deleted event image from Firebase Storage: $bannerUrl');
        } catch (e) {
          print('Error deleting event image $bannerUrl from Firebase Storage: $e. Firestore document was deleted.');
          // Consider if this error should be re-thrown or handled differently.
        }
      }
    } on FirebaseException catch (e) {
      print('Error deleting event $eventId from Firestore: ${e.message}');
      throw Exception('Failed to delete event: ${e.message}');
    } catch (e) {
      print('An unexpected error occurred while deleting event $eventId: $e');
      throw Exception('An unexpected error occurred while deleting the event.');
    }
  }
}
