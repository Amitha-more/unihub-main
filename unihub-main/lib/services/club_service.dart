import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club.dart';
import '../models/user_model.dart'; // Assuming you might need this for detailed user info later

class ClubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _clubsCollectionName = 'clubs';
  final String _usersCollectionName = 'users'; // If you fetch user details

  Future<String> createClub(Club club) async {
    try {
      DocumentReference docRef = _firestore.collection(_clubsCollectionName).doc();
      Club clubWithId = club.copyWith(id: docRef.id); // Use copyWith to set ID
      await docRef.set(clubWithId.toFirestore());
      print('Club created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating club: $e');
      throw Exception('Failed to create club: ${e.toString()}');
    }
  }

  Future<void> updateClub(Club club) async {
    if (club.id.isEmpty) {
      throw ArgumentError('Club ID cannot be empty when updating a club.');
    }
    try {
      await _firestore
          .collection(_clubsCollectionName)
          .doc(club.id)
          .update(club.toFirestore()); // Relies on club.toFirestore() using 'admins'
      print('Club updated successfully: ${club.id}');
    } catch (e) {
      print('Error updating club ${club.id}: $e');
      throw Exception('Failed to update club: ${e.toString()}');
    }
  }

  Future<Club?> getClubById(String clubId) async {
    if (clubId.isEmpty) return null;
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
      await _firestore.collection(_clubsCollectionName).doc(clubId).get();
      if (docSnapshot.exists) {
        return Club.fromFirestore(docSnapshot, null);
      }
      return null;
    } catch (e) {
      print('Error getting club by ID $clubId: $e');
      throw Exception('Failed to get club by ID: ${e.toString()}');
    }
  }

  Stream<Club?> getClubStreamById(String clubId) {
    if (clubId.isEmpty) return Stream.value(null);
    return _firestore
        .collection(_clubsCollectionName)
        .doc(clubId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Club.fromFirestore(snapshot, null);
    }).handleError((error) {
      print("Error in club stream for $clubId: $error");
      return null;
    });
  }

  Stream<List<Club>> getAllClubsStream() {
    return _firestore
        .collection(_clubsCollectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Club.fromFirestore(doc, null))
        .toList())
        .handleError((error) {
      print("Error getting all clubs stream: $error");
      return <Club>[];
    });
  }

  Future<void> deleteClub(String clubId) async {
    if (clubId.isEmpty) throw ArgumentError('Club ID cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).delete();
      print('Club deleted: $clubId');
    } catch (e) {
      print('Error deleting club $clubId: $e');
      throw Exception('Failed to delete club: ${e.toString()}');
    }
  }

  Future<void> requestToJoinClub(String clubId, String userId) async {
    if (clubId.isEmpty || userId.isEmpty) throw ArgumentError('IDs cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).update({
        'joinRequests': FieldValue.arrayUnion([userId])
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to request join: ${e.message}');
    }
  }

  Future<void> leaveClub(String clubId, String userId) async {
    if (clubId.isEmpty || userId.isEmpty) throw ArgumentError('IDs cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).update({
        'members': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId]), // <<<< Ensure this uses 'admins'
        'joinRequests': FieldValue.arrayRemove([userId])
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to leave club: ${e.message}');
    }
  }

  Future<void> approveJoinRequest(String clubId, String userIdToApprove) async {
    if (clubId.isEmpty || userIdToApprove.isEmpty) throw ArgumentError('IDs cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).update({
        'members': FieldValue.arrayUnion([userIdToApprove]),
        'joinRequests': FieldValue.arrayRemove([userIdToApprove])
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to approve request: ${e.message}');
    }
  }

  Future<void> rejectJoinRequest(String clubId, String userIdToReject) async {
    if (clubId.isEmpty || userIdToReject.isEmpty) throw ArgumentError('IDs cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).update({
        'joinRequests': FieldValue.arrayRemove([userIdToReject])
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to reject request: ${e.message}');
    }
  }

  Future<void> addAdminToClub(String clubId, String userIdToMakeAdmin) async {
    if (clubId.isEmpty || userIdToMakeAdmin.isEmpty) throw ArgumentError('IDs cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).update({
        'admins': FieldValue.arrayUnion([userIdToMakeAdmin]), // <<<< Ensure this uses 'admins'
        'members': FieldValue.arrayUnion([userIdToMakeAdmin])
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to add admin: ${e.message}');
    }
  }

  Future<void> removeMemberFromClub(String clubId, String userIdToRemove) async {
    if (clubId.isEmpty || userIdToRemove.isEmpty) throw ArgumentError('IDs cannot be empty.');
    try {
      await _firestore.collection(_clubsCollectionName).doc(clubId).update({
        'members': FieldValue.arrayRemove([userIdToRemove]),
        'admins': FieldValue.arrayRemove([userIdToRemove]) // <<<< Ensure this uses 'admins'
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to remove member: ${e.message}');
    }
  }

  // Helper to fetch user details (assuming UserModel and users collection)
  // Inside lib/services/club_service.dart
  Future<UserModel?> fetchUser(String uid) async {
    if (uid.isEmpty) return null;
    try {
      // Assuming _usersCollectionName is 'users'
      final doc = await _firestore.collection(_usersCollectionName).doc(uid).get();
      if (doc.exists) {
        // CORRECT WAY TO CALL IT:
        return UserModel.fromFirestore(doc); // Pass the DocumentSnapshot and null for options
      }
      return null;
    } catch (e) {
      print("Error fetching user $uid: $e");
      return null;
    }
  }
}
