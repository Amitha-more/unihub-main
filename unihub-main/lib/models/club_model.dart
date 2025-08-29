import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoUrl;
  final List<String> members;
  final List<String> admins;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.logoUrl,
    required this.members,
    required this.admins,
    required this.tags,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ClubModel.empty() {
    return ClubModel(
      id: '',
      name: '',
      description: '',
      category: '',
      logoUrl: '',
      members: [],
      admins: [],
      tags: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'logoUrl': logoUrl,
      'members': members,
      'admins': admins,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  bool isMember(String userId) => members.contains(userId);
  bool isAdmin(String userId) => admins.contains(userId);

  ClubModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? logoUrl,
    List<String>? members,
    List<String>? admins,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ClubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 