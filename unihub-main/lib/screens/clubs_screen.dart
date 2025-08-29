import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/club.dart';
import '../services/club_service.dart'; // We'll need to add methods here
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Assuming this model exists and is correct
import 'package:google_fonts/google_fonts.dart';
// Import your ClubCreateEditScreen
import 'club_create_edit_screen.dart'; // Make sure this path is correct

class ClubDetailsScreen extends StatefulWidget {
  final Club club; // Initial club data passed to the screen
  const ClubDetailsScreen({super.key, required this.club});

  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  late Club _club; // Use a local state variable for the club
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = false;
  String? _error;
  final ClubService _clubService = ClubService(); // Instance of ClubService

  @override
  void initState() {
    super.initState();
    _club = widget.club;
  }

  // Corrected getters using _club (local state) and _currentUserId
  bool get _isAdmin => _currentUserId != null && _club.admins.contains(_currentUserId!);
  bool get _isMember => _currentUserId != null && _club.members.contains(_currentUserId!);
  bool get _hasRequested => _currentUserId != null && _club.joinRequests.contains(_currentUserId!);

  Future<void> _refreshClubData() async {
    if (_club.id.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      Club? updatedClub = await _clubService.getClubById(_club.id);
      if (updatedClub != null && mounted) {
        setState(() {
          _club = updatedClub;
          _error = null;
        });
      } else if (mounted) {
        setState(() {
          _error = "Could not refresh club data.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Placeholder methods for ClubService actions ---
  // You'll need to implement these in your ClubService
  // and then call them here.

  Future<void> _requestToJoin() async {
    if (_currentUserId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // Assuming ClubService().requestToJoinClub(clubId, userId)
      await _clubService.requestToJoinClub(_club.id, _currentUserId!);
      await _refreshClubData(); // Refresh data to show updated state
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _leaveClub() async {
    if (_currentUserId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // Assuming ClubService().leaveClub(clubId, userId)
      await _clubService.leaveClub(_club.id, _currentUserId!);
      await _refreshClubData();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _approveRequest(String requestUid) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Assuming ClubService().approveJoinRequest(clubId, userIdToApprove)
      await _clubService.approveJoinRequest(_club.id, requestUid);
      await _refreshClubData();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _rejectRequest(String requestUid) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Assuming ClubService().rejectJoinRequest(clubId, userIdToReject)
      await _clubService.rejectJoinRequest(_club.id, requestUid);
      await _refreshClubData();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _deleteClub() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Club'),
        content: Text('Are you sure you want to delete \'${_club.name}\'? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() { _isLoading = true; _error = null; });
      try {
        await _clubService.deleteClub(_club.id);
        if (mounted) {
          Navigator.of(context).pop(); // Go back after deletion
        }
      } catch (e) {
        if (mounted) setState(() { _error = e.toString(); });
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _cancelJoinRequest() async {
    if (_currentUserId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // This is essentially rejecting your own request
      await _clubService.rejectJoinRequest(_club.id, _currentUserId!);
      await _refreshClubData();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _promoteToAdmin(String memberUid) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Assuming ClubService().addAdminToClub(clubId, userIdToMakeAdmin)
      await _clubService.addAdminToClub(_club.id, memberUid);
      await _refreshClubData();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _removeMember(String memberUid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'), // Fetch user name if needed for dialog
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() { _isLoading = true; _error = null; });
      try {
        // Assuming ClubService().removeMemberFromClub(clubId, userIdToRemove)
        await _clubService.removeMemberFromClub(_club.id, memberUid);
        await _refreshClubData();
      } catch (e) {
        if (mounted) setState(() { _error = e.toString(); });
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  Future<UserModel?> _fetchUser(String uid) async {
    // print('[DEBUG] Fetching user for UID: $uid'); // Keep for debugging if needed
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) {
      // print('[DEBUG] User document not found for UID: $uid');
      return null;
    }
    // Assuming UserModel.fromFirestore exists and is correct
    final user = UserModel.fromFirestore(doc);
    // print('[DEBUG] User fetched for UID $uid: name="${user.name}", branch="${user.branch}"');
    return user;
  }

  void _navigateToEditClubScreen() async {
    // Navigate to the edit screen and wait for a result (the updated club)
    final result = await Navigator.of(context).push<Club>( // Expect a Club object back
      MaterialPageRoute(
        builder: (context) => ClubCreateEditScreen(club: _club),
      ),
    );

    // If the edit screen returned an updated club, refresh the UI
    if (result != null && mounted) {
      setState(() {
        _club = result; // Update the local club state
        _error = null;  // Clear any previous errors
      });
    } else {
      // Optionally, refresh even if no specific result is returned,
      // in case of background updates or if you don't pop with result.
      _refreshClubData();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _club.name,
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 30), // Adjusted size
        ),
        actions: [
          if (_isAdmin) // Admin actions
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : _navigateToEditClubScreen,
              tooltip: 'Edit Club',
            ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteClub,
              tooltip: 'Delete Club',
            ),
        ],
      ),
      body: _isLoading && _club.members.isEmpty // Show loading only if initial data isn't there
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshClubData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Banner Style Logo ---
              Hero( // Keep Hero if you want animation from a previous screen
                tag: 'clubLogo_${_club.id}', // Ensure this tag matches
                child: Container(
                  height: 200, // Define your desired banner height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Optional: Add a background color if the image is transparent or for loading states
                    // color: Colors.grey[200],
                    image: (_club.logoUrl != null && _club.logoUrl!.isNotEmpty)
                        ? DecorationImage(
                      image: NetworkImage(_club.logoUrl!),
                      fit: BoxFit.contain, // Covers the area, might crop
                      onError: (exception, stackTrace) {
                        // Optional: You could log the error or handle it differently
                        // For now, it will just show the container background or nothing if no color set
                      },
                    )
                        : null, // No image if URL is null or empty
                  ),
                  // Fallback icon if there's no image or if image fails to load
                  // and no DecorationImage is applied.
                  child: (_club.logoUrl == null || _club.logoUrl!.isEmpty)
                      ? Center(child: Icon(Icons.group, size: 80, color: Colors.grey[400]))
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(_club.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Center(child: Text(_club.category, style: TextStyle(color: Colors.grey[700], fontSize: 16))),
              const SizedBox(height: 16),
              Text(_club.description, style: const TextStyle(fontSize: 16), textAlign: TextAlign.justify,),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.people_outline, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('Members: ${_club.members.length}', style: TextStyle(color: Colors.grey[800])),

                ],
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),

              // --- Action Buttons ---
              if (!_isMember && !_hasRequested && _currentUserId != null)
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestToJoin,
                  child: const Text('Request to Join'),
                )),
              if (_hasRequested && _currentUserId != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Join request pending approval.', style: TextStyle(color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _cancelJoinRequest,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Cancel Join Request'),
                    ),
                  ],
                ),
              if (_isMember && !_isAdmin && _currentUserId != null) // Member but not Admin
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _isLoading ? null : _leaveClub,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Leave Club'),
                )),

              const Divider(height: 32, thickness: 1),

              // --- Admin Section: Join Requests ---
              if (_isAdmin) ...[
                Text('Pending Join Requests (${_club.joinRequests.length})', style: Theme.of(context).textTheme.titleLarge),
                if (_club.joinRequests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No pending requests.'),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _club.joinRequests.length,
                  itemBuilder: (context, index) {
                    final uid = _club.joinRequests[index];
                    return FutureBuilder<UserModel?>(
                      future: _fetchUser(uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const ListTile(title: Text('Loading user...'));
                        }
                        final user = snapshot.data;
                        if (user == null) {
                          return ListTile(
                            title: Text('User ID: $uid (Not found or error)'),
                            trailing: IconButton(icon: Icon(Icons.delete_forever, color: Colors.grey), onPressed: () => _rejectRequest(uid), tooltip: "Remove invalid request"),
                          );
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "U")),
                            title: Text(user.name),
                            subtitle: Text(user.branch),
                            trailing: _isLoading ? CircularProgressIndicator(strokeWidth: 2) : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  onPressed: () => _approveRequest(uid),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                  onPressed: () => _rejectRequest(uid),
                                  tooltip: 'Reject',
                                ),
                              ],
                            ),
                          ),
                        );

                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // --- Members List ---
              Text('Members (${_club.members.length})', style: Theme.of(context).textTheme.titleLarge),
              if (_club.members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No members yet.'),
                ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _club.members.length,
                itemBuilder: (context, index) {
                  final uid = _club.members[index];
                  final bool isThisUserAdmin = _club.admins.contains(uid);
                  return FutureBuilder<UserModel?>(
                    future: _fetchUser(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const ListTile(title: Text('Loading member...'));
                      }
                      final user = snapshot.data;
                      if (user == null) {
                        return ListTile(title: Text('User ID: $uid (Not found or error)'));
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "U")),
                          title: Text(user.name),
                          subtitle: Text(user.branch),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isThisUserAdmin)
                                const Tooltip(message: "Club Admin", child: Icon(Icons.star, color: Colors.amber)),
                              if (_isAdmin && !isThisUserAdmin) // Current user is admin & this member is not
                                Tooltip(
                                  message: "Promote to Admin",
                                  child: IconButton(
                                    icon: const Icon(Icons.admin_panel_settings_outlined),
                                    onPressed: _isLoading ? null : () => _promoteToAdmin(uid),
                                  ),

                                ),
                              if (_isAdmin && uid != _currentUserId) // Admin can remove anyone but themselves
                                Tooltip(
                                  message: "Remove Member",
                                  child: IconButton(
                                    icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                                    onPressed: _isLoading ? null : () => _removeMember(uid),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],

          ),
        ),
      ),
    );
  }
}

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  String? _currentUserId;
  bool _isAdminOfAnyClub = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _checkIfAdminOfAnyClub();
  }

  Future<void> _checkIfAdminOfAnyClub() async {
    if (_currentUserId == null) return;
    final clubService = ClubService();
    final clubsStream = clubService.getAllClubsStream();
    clubsStream.first.then((clubs) {
      final isAdmin = clubs.any((club) => club.admins.contains(_currentUserId));
      if (mounted) setState(() => _isAdminOfAnyClub = isAdmin);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clubs',
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 50,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: StreamBuilder<List<Club>>(

        stream: ClubService().getAllClubsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No clubs found.'));
          }
          final clubs = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: clubs.length,
              itemBuilder: (context, index) {
                final club = clubs[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClubDetailsScreen(club: club),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                club.logoUrl!,
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                            )

                          else
                            const Icon(Icons.group, size: 70, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            club.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            club.category,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );

        },
      ),
      floatingActionButton: _isAdminOfAnyClub
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ClubCreateEditScreen()),
                );
                setState(() {}); // Refresh after returning
              },
              tooltip: 'Add Club',
              child: const Icon(Icons.add),
            )

          : null,
    );
  }
}
