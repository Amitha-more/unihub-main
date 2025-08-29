import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore query
import '../models/event.dart';
import '../services/event_service.dart';
import 'dashboard_screen.dart';
import 'event_details_screen.dart'; 
import 'dart:async';
import 'create_edit_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();
  List<Event> upcomingEvents = [];
  bool isLoading = true;

  List<Event> _rawUpcomingEvents = [];
  Set<String> _cachedRegisteredEventIds = {};

  StreamSubscription<List<Event>>? _upcomingEventsSubscription;
  StreamSubscription<List<Event>>? _registeredEventsSubscription;

  bool _hasInitialUpcoming = false;
  bool _hasInitialRegistered = false;

  String? _currentUserId;
  bool _isCurrentUserAdmin = false; 

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _subscribeToEvents();
    _checkAdminStatus(); 
  }

  Future<void> _checkAdminStatus() async {
    if (_currentUserId == null) {
      if (mounted) {
        setState(() {
          _isCurrentUserAdmin = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users') 
          .doc(_currentUserId)
          .get();

      if (mounted) {
        if (userDoc.exists && userDoc.data()?['isGlobalAdmin'] == true) {
          setState(() {
            _isCurrentUserAdmin = true;
          });
        } else {
          setState(() {
            _isCurrentUserAdmin = false;
          });
        }
      }
    } catch (e) {
      print('Error checking admin status in EventsScreen: $e');
      if (mounted) {
        setState(() {
          _isCurrentUserAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _upcomingEventsSubscription?.cancel();
    _registeredEventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _subscribeToEvents() async {
    setState(() {
      isLoading = true;
      _hasInitialUpcoming = false;
      _hasInitialRegistered = false;
      upcomingEvents.clear();
      _rawUpcomingEvents.clear();
      _cachedRegisteredEventIds.clear();
    });

    _upcomingEventsSubscription?.cancel();
    _registeredEventsSubscription?.cancel();

    _upcomingEventsSubscription = _eventService.getUpcomingEvents().listen(
      (events) {
        if (mounted) {
          _rawUpcomingEvents = events;
          _hasInitialUpcoming = true;
          _updateEventLists();
        }
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading upcoming events: $e')),
          );
          if (!_hasInitialRegistered) { 
            setState(() => isLoading = false);
          }
        }
      },
    );

    _registeredEventsSubscription = _eventService.getRegisteredEvents().listen(
      (registered) {
        if (mounted) {
          _cachedRegisteredEventIds = registered.map((e) => e.id).toSet();
          _hasInitialRegistered = true;
          _updateEventLists();
        }
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading registered event IDs: $e')),
          );
           if (!_hasInitialUpcoming) { 
            setState(() => isLoading = false);
          }
        }
      },
    );
  }

  void _updateEventLists() {
    if (!mounted) return;

    if (_hasInitialUpcoming && _hasInitialRegistered) {
      setState(() {
        upcomingEvents = _rawUpcomingEvents
            .where((event) => !_cachedRegisteredEventIds.contains(event.id))
            .toList();
        isLoading = false;
      });
    }
  }

  Future<void> _registerForEvent(Event event) async {
    try {
      await _eventService.registerForEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully registered for ${event.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering for event: $e')),
        );
      }
    }
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(event.dateTime)} • ${_formatTime(event.dateTime)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800] ?? Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Events',
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 50,
            color: Colors.black,
            fontWeight: FontWeight.w300,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _subscribeToEvents,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Upcoming Events',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (upcomingEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'No upcoming events available',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingEvents.length,
                itemBuilder: (context, index) {
                  final event = upcomingEvents[index];
                  return _buildEventCard(event);
                },
              ),
          ],
        ),
      ),
      floatingActionButton: _isCurrentUserAdmin 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEditEventScreen()),
              );
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create Event',
          )
        : null,
    );
  }
}
