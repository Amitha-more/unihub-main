import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePicUrl;
  final String? bio;
  final String branch;
  final int year;
  final List<String> clubsJoined;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePicUrl,
    this.bio,
    required this.branch,
    required this.year,
    required this.clubsJoined,
    this.fcmToken,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      email: '',
      name: '',
      branch: '',
      year: 1,
      clubsJoined: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      profilePicUrl: data['profilePicUrl'],
      bio: data['bio'],
      branch: data['branch'] ?? '',
      year: (data['year'] ?? 1) as int,
      clubsJoined: List<String>.from(data['clubsJoined'] ?? []),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'profilePicUrl': profilePicUrl,
      'bio': bio,
      'branch': branch,
      'year': year,
      'clubsJoined': clubsJoined,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profilePicUrl,
    String? bio,
    String? branch,
    int? year,
    List<String>? clubsJoined,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bio: bio ?? this.bio,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      clubsJoined: clubsJoined ?? this.clubsJoined,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 