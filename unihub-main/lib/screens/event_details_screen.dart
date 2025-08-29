import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure this is imported for _checkAdminStatus
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:add_2_calendar/add_2_calendar.dart' show Add2Calendar;
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/create_edit_event_screen.dart';

// Helper enum for PopupMenuButton item values
enum _EventAction { share, addToCalendar, edit, delete }

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistering = false;
  bool _isRegistered = false;
  bool _isNotificationEnabled = false;
  final _eventService = EventService();
  final _notificationService = NotificationService();

  String? _currentUserId;
  bool _isCurrentUserAdmin = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _checkRegistrationStatus();
    _checkNotificationStatus();
    _checkAdminStatus(); // This will now use the Firestore logic
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
          .collection('users') // Collection name for user profiles
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
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isCurrentUserAdmin = false;
        });
      }
    }
  }

  Future<void> _checkRegistrationStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final isRegistered = await _eventService.isUserRegistered(widget.event.id);
      if (mounted) {
        setState(() {
          _isRegistered = isRegistered;
        });
      }
    }
  }

  Future<void> _checkNotificationStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final isEnabled = await _notificationService.isNotificationEnabled(widget.event.id);
      if (mounted) {
        setState(() {
          _isNotificationEnabled = isEnabled;
        });
      }
    }
  }

  Future<void> _toggleRegistration() async {
    if (_isRegistering) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to register for events')),
        );
        return;
      }

      if (_isRegistered) {
        await _eventService.cancelRegistration(widget.event.id);
        setState(() {
          _isRegistered = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled successfully')),
          );
        }
      } else {
        await _eventService.registerForEvent(widget.event.id);
        setState(() {
          _isRegistered = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Registered successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _toggleNotification() async {
    try {
      if (_isNotificationEnabled) {
        await _notificationService.cancelEventNotification(widget.event.id);
      } else {
        await _notificationService.scheduleEventNotification(
          eventId: widget.event.id,
          title: widget.event.title,
          body: '''Your event "${widget.event.title}" starts in 1 hour!''',
          eventTime: widget.event.dateTime,
        );
      }
      await _checkNotificationStatus(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _addToCalendar() {
    final calendarEvent = calendar.Event(
      title: widget.event.title,
      description: widget.event.description,
      location: widget.event.location,
      startDate: widget.event.dateTime,
      endDate: widget.event.dateTime.add(const Duration(hours: 2)),
    );
    Add2Calendar.addEvent2Cal(calendarEvent);
  }

  void _shareEvent() {
    final message = '''
${widget.event.title}

📅 ${DateFormat('''MMM d, y • h:mm a''').format(widget.event.dateTime)}
📍 ${widget.event.location}

${widget.event.description}

Organized by: ${widget.event.organizer}
''';
    Share.share(message);
  }

  void _navigateToEditEventScreen() {
    if (!_isCurrentUserAdmin) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditEventScreen(event: widget.event),
      ),
    ).then((_) {
      // Optional: Refresh or handle result after edit screen pops
    });
  }

  Future<void> _showDeleteConfirmationDialog() async {
    if (_isDeleting) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('''Are you sure you want to delete the event "${widget.event.title}"?'''),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: _isDeleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteEvent();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent() async {
    if (!mounted) return;
    setState(() {
      _isDeleting = true;
    });

    try {
      await _eventService.deleteEvent(widget.event.id, widget.event.bannerUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('''Event "${widget.event.title}" deleted successfully.''')),
        );
        Navigator.of(context).pop(); // Pop current screen after delete
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('''Error deleting event: ${e.toString()}''')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '''Event Details''',
          style: TextStyle(
            fontFamily: '''Jersey10''',
            fontSize: 30,
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isNotificationEnabled ? Icons.notifications_active : Icons.notifications_none,
              color: _isNotificationEnabled ? Theme.of(context).primaryColor : null,
            ),
            tooltip: _isNotificationEnabled ? '''Disable Notifications''' : '''Enable Notifications''',
            onPressed: () async {
              await _toggleNotification();
            },
          ),
          if (!_isDeleting)
            PopupMenuButton<_EventAction>(
              onSelected: (_EventAction action) {
                switch (action) {
                  case _EventAction.share:
                    _shareEvent();
                    break;
                  case _EventAction.addToCalendar:
                    _addToCalendar();
                    break;
                  case _EventAction.edit:
                    _navigateToEditEventScreen();
                    break;
                  case _EventAction.delete:
                    _showDeleteConfirmationDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry<_EventAction>> items = [];
                items.add(
                  const PopupMenuItem<_EventAction>(
                    value: _EventAction.share,
                    child: ListTile(leading: Icon(Icons.share), title: Text('''Share Event''')),
                  ),
                );
                items.add(
                  const PopupMenuItem<_EventAction>(
                    value: _EventAction.addToCalendar,
                    child: ListTile(leading: Icon(Icons.calendar_today), title: Text('''Add to Calendar''')),
                  ),
                );
                if (_isCurrentUserAdmin) { // This now correctly uses the Firestore check
                  items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem<_EventAction>(
                      value: _EventAction.edit,
                      child: ListTile(leading: Icon(Icons.edit_note_outlined), title: Text('''Edit Event''')),
                    ),
                  );
                  items.add(
                    const PopupMenuItem<_EventAction>(
                      value: _EventAction.delete,
                      child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.redAccent), title: Text('''Delete Event''')),
                    ),
                  );
                }
                return items;
              },
              icon: const Icon(Icons.more_vert),
              tooltip: '''More options''',
            ),
          if (_isDeleting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0, color: Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event.bannerUrl != null)
              Image.network(
                widget.event.bannerUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.calendar_today,
                    '''Date & Time''',
                    DateFormat('''EEEE, MMMM d, y • h:mm a''').format(widget.event.dateTime),
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    '''Location''',
                    widget.event.location,
                  ),
                  _buildDetailRow(
                    Icons.group,
                    '''Organizer''',
                    widget.event.organizer,
                  ),
                  _buildDetailRow(
                    Icons.description,
                    '''Description''',
                    widget.event.description,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isRegistering ? null : _toggleRegistration,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isRegistering
              ? const CircularProgressIndicator()
              : Text(
                  _isRegistered ? '''Cancel Registration''' : '''Register Now''',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
