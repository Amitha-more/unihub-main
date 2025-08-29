import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;
  String name;
  String description;
  String? logoUrl;
  String category;
  List<String> members;
  List<String> admins; // <<<< FIELD IS NOW PLURAL 'admins'
  List<String> joinRequests;
  final DateTime createdAt;
  // DateTime? updatedAt; // Optional

  Club({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.category,
    required this.members,
    required this.admins, // <<<< FIELD IS NOW PLURAL 'admins'
    required this.joinRequests,
    required this.createdAt,
    // this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      'category': category,
      'members': members,
      'admins': admins, // <<<< MAP KEY IS NOW PLURAL 'admins'
      'joinRequests': joinRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      // if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory Club.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for Club ID: ${snapshot.id}');
    }

    // Read 'admins' field, with a fallback for old 'admin' field during transition
    List<String> adminList = [];
    if (data['admins'] != null) {
      adminList = List<String>.from(data['admins'] as List<dynamic>? ?? []);
    } else if (data['admin'] != null) {
      // This fallback is for safety if you have old documents.
      // Remove it once all documents use 'admins'.
      print("Warning: Club ${snapshot.id} is using the old 'admin' field. Please migrate to 'admins'.");
      adminList = List<String>.from(data['admin'] as List<dynamic>? ?? []);
    }

    return Club(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Unnamed Club',
      description: data['description'] as String? ?? 'No description.',
      logoUrl: data['logoUrl'] as String?,
      category: data['category'] as String? ?? 'Uncategorized',
      members: List<String>.from(data['members'] as List<dynamic>? ?? []),
      admins: adminList, // <<<< ASSIGNING FROM 'admins' (or fallback)
      joinRequests: List<String>.from(data['joinRequests'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    bool clearLogoUrl = false,
    String? category,
    List<String>? members,
    List<String>? admins, // <<<< PARAM IS NOW PLURAL 'admins'
    List<String>? joinRequests,
    DateTime? createdAt,
    // DateTime? updatedAt,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: clearLogoUrl ? null : logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      members: members ?? this.members,
      admins: admins ?? this.admins, // <<<< PROPERTY IS NOW PLURAL 'admins'
      joinRequests: joinRequests ?? this.joinRequests,
      createdAt: createdAt ?? this.createdAt,
      // updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Add this getter for backward compatibility
  String get admin => admins.isNotEmpty ? admins.first : '';
}
