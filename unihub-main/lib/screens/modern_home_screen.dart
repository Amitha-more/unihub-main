import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import 'events_screen.dart';
import 'event_details_screen.dart';
import 'clubs_screen.dart';
import 'registered_events_screen.dart';
// import 'global_search_screen.dart'; // Commented out as per user request


class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  final _eventService = EventService();
  final _searchController = TextEditingController();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'] ?? 'Student';
          });
        } else {
          setState(() {
            _userName = 'Student';
          });
        }
      } catch (e) {
        // print('Error loading user name: $e'); // Already commented
        setState(() {
          _userName = 'Student';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildAppBar(),
            _buildGreeting(),
            _buildSearchBar(),
            _buildFeaturedEvents(),
            _buildQuickAccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  'Uni',
                  style: const TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A6FFF),
                  ),
                ),
              ),
              Text(
                'HUB',
                style: const TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${_userName ?? 'there'}! 👋',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Discover what\'s happening on campus',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search clubs, events, and more...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black38,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // onSubmitted: (query) {
          //   if (query.trim().isNotEmpty) {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => GlobalSearchScreen(searchQuery: query.trim()),
          //       ),
          //     );
          //   }
          // },
        ),
      ),
    );
  }

  Widget _buildFeaturedEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Events',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventsScreen()),
                  );// Navigation handled by dashboard
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: StreamBuilder<List<Event>>(
            stream: _eventService.getUpcomingEvents(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    'No upcoming events',
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                );
              }

              // Only show first 3 events in preview
              final previewEvents = events.take(3).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: previewEvents.length,
                itemBuilder: (context, index) {
                  final event = previewEvents[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)),
                      );
                    },
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: event.bannerUrl != null
                                  ? Image.network(
                                      event.bannerUrl!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 120,
                                      color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()), 
                                      child: const Icon(
                                        Icons.event,
                                        size: 48,
                                        color: Colors.black26,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(event.dateTime),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    final quickAccessItems = [
      _QuickAccessItem(
        icon: Icons.search,
        label: 'Lost & Found',
        color: Colors.orange,
        onTap: () {
          // Navigate to Lost & Found
        },
      ),
      _QuickAccessItem(
        icon: Icons.event_note,
        label: 'My Events',
        color: Colors.blue,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RegisteredEventsScreen()),
          );
        },
      ),
      _QuickAccessItem(
        icon: Icons.notifications,
        label: 'Reminders',
        color: Colors.purple,
        onTap: () {
          // Navigate to Reminders
        },
      ),
      _QuickAccessItem(
        icon: Icons.groups,
        label: 'Clubs',
        color: Colors.green,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ClubsScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Quick Access',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: quickAccessItems.map((item) {
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withAlpha((255 * 0.1).round()), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.color.withAlpha((255 * 0.2).round()), 
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 32,
                      color: item.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
