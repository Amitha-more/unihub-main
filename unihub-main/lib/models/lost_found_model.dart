import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { lost, found, claimed, resolved }

class LostFoundModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String? imageUrl;
  final String userId;
  final String userEmail;
  final String userName;
  final ItemStatus status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isModerated;

  LostFoundModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.imageUrl,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.status,
    required this.tags,
    required this.createdAt,
    required this.lastUpdated,
    this.isModerated = false,
  });

  factory LostFoundModel.empty() {
    return LostFoundModel(
      id: '',
      title: '',
      description: '',
      location: '',
      date: DateTime.now(),
      userId: '',
      userEmail: '',
      userName: '',
      status: ItemStatus.lost,
      tags: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  factory LostFoundModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostFoundModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      status: ItemStatus.values.firstWhere(
        (e) => e.toString() == 'ItemStatus.${data['status'] ?? 'lost'}',
        orElse: () => ItemStatus.lost,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      isModerated: data['isModerated'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'status': status.toString().split('.').last,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isModerated': isModerated,
    };
  }

  LostFoundModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    String? imageUrl,
    String? userId,
    String? userEmail,
    String? userName,
    ItemStatus? status,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isModerated,
  }) {
    return LostFoundModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isModerated: isModerated ?? this.isModerated,
    );
  }

  bool get isPending => !isModerated;
  bool get isResolved => status == ItemStatus.resolved;
  bool get isClaimed => status == ItemStatus.claimed;
  bool get isActive => status == ItemStatus.lost || status == ItemStatus.found;
} 