import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/club.dart';
import '../services/club_service.dart';
import '../models/user_model.dart'; // For UserModel
import 'package:google_fonts/google_fonts.dart';
import 'club_create_edit_screen.dart'; // For navigation

const Color orangeRed = Color(0xFFFF4500);

class ClubDetailsScreen extends StatefulWidget {
  final String clubId; // Pass clubId for fresh data
  const ClubDetailsScreen({Key? key, required this.clubId}) : super(key: key);

  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  Club? _club;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  String? _error;
  final ClubService _clubService = ClubService();
  StreamSubscription<Club?>? _clubSubscription;

  @override
  void initState() {
    super.initState();
    _listenToClubUpdates();
  }

  @override
  void dispose() {
    _clubSubscription?.cancel();
    super.dispose();
  }

  void _listenToClubUpdates() {
    if (widget.clubId.isEmpty) {
      setState(() {
        _error = "Club ID is invalid.";
        _isLoading = false;
      });
      return;
    }
    _isLoading = true; // Set loading true when starting to listen
    _clubSubscription = _clubService.getClubStreamById(widget.clubId).listen(
          (updatedClub) {
        if (!mounted) return;
        setState(() {
          _club = updatedClub;
          _isLoading = false; // Data received or club doesn't exist
          _error = updatedClub == null && widget.clubId.isNotEmpty ? "Club not found." : null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = "Error: ${error.toString()}";
          _isLoading = false;
        });
      },
    );
  }

  // Getters based on _club and _currentUserId
  bool get _isUserAdmin => _currentUserId != null && _club != null && _club!.admins.contains(_currentUserId!);
  bool get _isUserMember => _currentUserId != null && _club != null && _club!.members.contains(_currentUserId!);
  bool get _hasUserRequested => _currentUserId != null && _club != null && _club!.joinRequests.contains(_currentUserId!);

  Future<void> _performClubAction(Future<void> Function() action) async {
    if (_club == null || _currentUserId == null) {
      setState(() => _error = "Cannot perform action: Data missing or not logged in.");
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await action();
      // Data will refresh via the stream, so no explicit setState for _club here
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      //isLoading will be set to false by stream update
      //However, if stream doesn't update quickly or action fails before stream,
      // it might be good to ensure isLoading is false if no stream update comes.
      // For simplicity now, relying on stream.
      if (mounted && _error != null) setState(() => _isLoading = false);
    }
  }

  void _requestToJoin() => _performClubAction(() => _clubService.requestToJoinClub(_club!.id, _currentUserId!));
  void _leaveClub() => _performClubAction(() => _clubService.leaveClub(_club!.id, _currentUserId!));
  void _approveRequest(String uid) => _performClubAction(() => _clubService.approveJoinRequest(_club!.id, uid));
  void _rejectRequest(String uid) => _performClubAction(() => _clubService.rejectJoinRequest(_club!.id, uid));
  void _cancelJoinRequest() => _performClubAction(() => _clubService.rejectJoinRequest(_club!.id, _currentUserId!)); // Reject uses same logic
  void _addAdmin(String uid) => _performClubAction(() => _clubService.addAdminToClub(_club!.id, uid));
  void _removeMember(String uid) => _performClubAction(() => _clubService.removeMemberFromClub(_club!.id, uid));

  Future<void> _deleteClub() async {
    if (_club == null || !_isUserAdmin) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Club?'),
        content: Text('Are you sure you want to permanently delete "${_club!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      _performClubAction(() async {
        await _clubService.deleteClub(_club!.id);
        if (mounted) Navigator.of(context).pop(); // Pop after successful deletion
      });
    }
  }

  void _navigateToEditClub() {
    if (_club != null && _isUserAdmin) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ClubCreateEditScreen(club: _club)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _club == null) { // Initial full screen load
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _club == null) { // Critical error, club not found
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
        )),
      );
    }
    if (_club == null) { // Should not happen if error handling is correct, but as a fallback
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("Club data not available.")));
    }

    // Main content build using _club!
    return Scaffold(
      appBar: AppBar(
        title: Text(_club!.name, style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          if (_isUserAdmin)
            IconButton(icon: const Icon(Icons.edit_note), onPressed: _navigateToEditClub, tooltip: 'Edit Club'),
          if (_isUserAdmin)
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: _isLoading ? null : _deleteClub, tooltip: 'Delete Club'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _listenToClubUpdates(); // Re-establish stream or re-fetch
        },
        child: SingleChildScrollView(
          // No top padding here for the banner to go edge-to-edge if the banner is inside SingleChildScrollView
          // OR, if banner is outside, keep padding on SingleChildScrollView.
          // Let's assume banner is the first child of the Column *inside* SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Banner Style Logo ---
              Hero( // Keep Hero if you want animation from a previous screen
                tag: 'clubLogo_${_club!.id}', // Ensure this tag matches
                child: Container(
                  height: 200, // Define your desired banner height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Optional: Add a background color if the image is transparent or for loading states
                    // color: Colors.grey[200],
                    image: (_club!.logoUrl != null && _club!.logoUrl!.isNotEmpty)
                        ? DecorationImage(
                      image: NetworkImage(_club!.logoUrl!),
                      fit: BoxFit.cover, // Covers the area, might crop
                      onError: (exception, stackTrace) {
                        // Optional: You could log the error or handle it differently
                        // For now, it will just show the container background or nothing if no color set
                      },
                    )
                        : null, // No image if URL is null or empty
                  ),
                  // Fallback icon if there's no image or if image fails to load
                  // and no DecorationImage is applied.
                  child: (_club!.logoUrl == null || _club!.logoUrl!.isEmpty)
                      ? Center(child: Icon(Icons.group, size: 80, color: Colors.grey[400]))
                      : null, // If image is set, child is not needed unless for overlay
                  // Example of an overlay (e.g. for text protection)
                  // child: DecoratedBox(
                  //   decoration: BoxDecoration(
                  //     gradient: LinearGradient(
                  //       begin: Alignment.bottomCenter,
                  //       end: Alignment.topCenter,
                  //       colors: [
                  //         Colors.black.withOpacity(0.4),
                  //         Colors.transparent,
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ),
              ),
              // Padding for the rest of the content below the banner
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 16), // Spacing after banner, adjust as needed
                    Center(child: Text(_club!.name, style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold))),
                    Center(child: Text(_club!.category, style: TextStyle(color: Colors.grey[700], fontSize: 16, fontStyle: FontStyle.italic))),
                    const SizedBox(height: 16),
                    Text(_club!.description, style: const TextStyle(fontSize: 16, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Icon(Icons.people_alt_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('Members: ${_club!.members.length}', style: TextStyle(color: Colors.grey[800], fontSize: 15)),
                    ]),
                    const SizedBox(height: 24),

                    // ... (Rest of your content: Action Buttons, Admin Section, etc.)
                    // This part remains the same as your provided code.
                    // Ensure it's placed here, inside the Padding -> Column.

                    // Action Buttons
                    if (_isLoading && _club != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Center(child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth:2)))),
                    if (_error != null && _club != null) // Show error related to action if club is loaded
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 5),
                        child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ),

                    if (_currentUserId != null) ...[
                      if (!_isUserAdmin && !_isUserMember && !_hasUserRequested)
                        _buildFullWidthButton(icon: Icons.person_add_alt_1, text: 'Request to Join', onPressed: _requestToJoin),
                      if (_hasUserRequested)
                        Column(children: [
                          Text('Join request sent. Waiting for approval.', style: TextStyle(color: Theme.of(context).primaryColor)),
                          const SizedBox(height: 8),
                          _buildFullWidthButton(icon: Icons.cancel_outlined, text: 'Cancel Join Request', onPressed: _cancelJoinRequest, color: Colors.orange),
                        ]),
                      if (_isUserMember && !_isUserAdmin) // Member but not Admin
                        _buildFullWidthButton(icon: Icons.exit_to_app, text: 'Leave Club', onPressed: _leaveClub, color: Colors.redAccent),
                    ],
                    if (_currentUserId == null)
                      const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Login to interact with this club.", style: TextStyle(fontStyle: FontStyle.italic)))),

                    // Admin Section
                    if (_isUserAdmin) ...[
                      const Divider(height: 32, thickness: 1),
                      _buildSectionTitle('Pending Join Requests (${_club!.joinRequests.length})'),
                      if (_club!.joinRequests.isEmpty) const Text('No pending requests.'),
                      ..._club!.joinRequests.map((uid) => _buildUserTile(uid, isRequest: true)),

                      const Divider(height: 32, thickness: 1),
                      _buildSectionTitle('Club Members (${_club!.members.length})'),
                      if (_club!.members.isEmpty) const Text('No members yet.'),
                      ..._club!.members.map((uid) => _buildUserTile(uid, isRequest: false)),
                    ],
                    // Public Member List (if not admin)
                    if (!_isUserAdmin && _club!.members.isNotEmpty) ...[
                      const Divider(height: 32, thickness: 1),
                      _buildSectionTitle('Club Members (${_club!.members.length})'),
                      ..._club!.members.map((uid) => _buildUserTile(uid, isRequest: false, publicView: true)),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFullWidthButton({required IconData icon, required String text, required VoidCallback onPressed, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 45),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUserTile(String uid, {required bool isRequest, bool publicView = false}) {
    return FutureBuilder<UserModel?>(
      future: _clubService.fetchUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return ListTile(
            leading: const CircleAvatar(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))),
            title: const Text('Loading user...'),
            subtitle: Text('ID: $uid', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          );
        }
        if (snapshot.hasError) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.error_outline, color: Colors.red)),
            title: const Text('Error loading user'),
            subtitle: Text('ID: $uid - ${snapshot.error}', style: const TextStyle(fontSize: 10, color: Colors.redAccent)),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_off_outlined)),
            title: Text('User not found'),
            subtitle: Text('ID: $uid', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          );
        }

        final user = snapshot.data!;
        // Determine if the current user is an admin of the club (used for showing admin-specific actions)
        final bool currentUserIsClubAdmin = _isUserAdmin; // Using the existing getter

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: CircleAvatar(
              // You might want to add user.profilePicUrl if available
              child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
            ),
            title: Text(user.name.isNotEmpty ? user.name : 'Unknown User'),
            subtitle: Text(user.branch.isNotEmpty ? user.branch : 'No branch info'),
            trailing: currentUserIsClubAdmin && !publicView // Show actions only if current user is admin and not in public view
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: isRequest
                  ? [ // Actions for join requests
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: 'Approve Request',
                  onPressed: _isLoading ? null : () => _approveRequest(uid),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  tooltip: 'Reject Request',
                  onPressed: _isLoading ? null : () => _rejectRequest(uid),
                ),
              ]
                  : [ // Actions for existing members (if current user is admin)
                // Only show "Make Admin" if the target user is not already an admin
                if (!_club!.admins.contains(uid))
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blueAccent),
                    tooltip: 'Make Admin',
                    onPressed: _isLoading ? null : () => _addAdmin(uid),
                  ),
                // Prevent self-removal or removing other admins if that's a desired logic (optional)
                // For simplicity, allowing removal now, but you might add checks here.
                // Ensure _currentUserId is not uid if you want to prevent self-removal.
                if (_currentUserId != uid) // Optional: Prevent self-removal
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: orangeRed),
                    tooltip: 'Remove Member',
                    onPressed: _isLoading ? null : () => _removeMember(uid),
                  ),
              ],
            )
                : null, // No trailing widget if not admin, or if it's a public view
          ),
        );
      },
    );
  }
}
