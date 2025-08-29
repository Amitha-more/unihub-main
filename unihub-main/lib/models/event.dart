import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime; // This remains DateTime for UI convenience
  final String location;
  final String? bannerUrl;
  final String? clubId;
  final String organizer;
  final String venue;
  final List<String> categories;
  final bool isFree;
  final int maxSeats;
  final int registeredCount;
  final List<String> registeredUserIds;
  final List<String> registeredUsers; // Consider changing to List<Map<String, dynamic>> if storing more user info
  final String status;
  final List<String> notificationEnabledUsers;
  final bool isNotificationEnabled;
  final String createdBy;
  final int? maxParticipants;
  // New fields for creation and update timestamps
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    this.bannerUrl,
    this.clubId,
    required this.organizer,
    required this.venue,
    required this.categories,
    required this.isFree,
    required this.maxSeats,
    required this.registeredCount,
    required this.registeredUserIds,
    required this.registeredUsers,
    required this.status,
    required this.notificationEnabledUsers,
    required this.isNotificationEnabled,
    required this.createdBy,
    this.maxParticipants,
    required this.createdAt, // Added to constructor
    required this.updatedAt, // Added to constructor
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(), // Convert to DateTime
      location: data['location'] ?? '',
      bannerUrl: data['bannerUrl'],
      clubId: data['clubId'],
      organizer: data['organizer'] ?? '',
      venue: data['venue'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      isFree: data['isFree'] ?? true,
      maxSeats: data['maxSeats'] ?? 0,
      registeredCount: data['registeredCount'] ?? 0,
      registeredUserIds: List<String>.from(data['registeredUserIds'] ?? []),
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []), // Adjust if type changes
      status: data['status'] ?? 'upcoming',
      notificationEnabledUsers: List<String>.from(data['notificationEnabledUsers'] ?? []),
      isNotificationEnabled: data['isNotificationEnabled'] ?? false,
      createdBy: data['createdBy'] ?? '',
      maxParticipants: data['maxParticipants'],
      // Read directly as Timestamp
      createdAt: data['createdAt'] ?? Timestamp.now(), // Provide a default if potentially null
      updatedAt: data['updatedAt'] ?? Timestamp.now(), // Provide a default if potentially null
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime), // Convert DateTime to Timestamp
      'location': location,
      'bannerUrl': bannerUrl,
      'clubId': clubId,
      'organizer': organizer,
      'venue': venue,
      'categories': categories,
      'isFree': isFree,
      'maxSeats': maxSeats,
      'registeredCount': registeredCount,
      'registeredUserIds': registeredUserIds,
      'registeredUsers': registeredUsers,
      'status': status,
      'notificationEnabledUsers': notificationEnabledUsers,
      'isNotificationEnabled': isNotificationEnabled,
      'createdBy': createdBy,
      'maxParticipants': maxParticipants,
      // Store directly as Timestamp
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isRegistrationFull => registeredCount >= maxSeats;
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  int get availableSpots => maxSeats - registeredCount;

  bool isUserRegistered(String userId) {
    return registeredUserIds.contains(userId);
  }

  // The 'empty' factory method will also need createdAt and updatedAt.
  // For a truly 'empty' or placeholder event, using Timestamp.now() is a reasonable default.
  static Event empty() {
    Timestamp now = Timestamp.now();
    return Event(
      id: '',
      title: '',
      description: '',
      dateTime: DateTime.now(),
      location: '',
      bannerUrl: null,
      clubId: null,
      organizer: '',
      venue: '',
      categories: [],
      isFree: true,
      maxSeats: 0,
      registeredCount: 0,
      registeredUserIds: [],
      registeredUsers: [],
      status: 'upcoming',
      notificationEnabledUsers: [],
      isNotificationEnabled: false,
      createdBy: '',
      createdAt: now, // Added
      updatedAt: now, // Added
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
