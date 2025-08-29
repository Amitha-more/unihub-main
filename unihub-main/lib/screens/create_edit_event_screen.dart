import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/event.dart'; // Using your existing event model
import '../services/event_service.dart';

class CreateEditEventScreen extends StatefulWidget {
  final Event? event; // Pass an event here if you're editing
  const CreateEditEventScreen({super.key, this.event});

  bool get isEditing => event != null;

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _maxSeatsController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController(); // For comma-separated categories

  DateTime? _selectedDateTime;
  XFile? _selectedImageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isEventFree = true; // Default for new events

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _selectedDateTime = widget.event!.dateTime;
      _existingImageUrl = widget.event!.bannerUrl;
      _organizerController.text = widget.event!.organizer;
      _venueController.text = widget.event!.venue;
      _maxSeatsController.text = widget.event!.maxSeats.toString();
      _categoriesController.text = widget.event!.categories.join(', ');
      _isEventFree = widget.event!.isFree;
    } else {
      // Default max seats for new event
      _maxSeatsController.text = '50';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _venueController.dispose();
    _maxSeatsController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          _existingImageUrl = null; 
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      _pickTime(pickedDate);
    }
  }

  Future<void> _pickTime(DateTime date) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    } else {
        setState(() {
             _selectedDateTime = date; 
        });
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception("User not logged in. Cannot upload image.");
    }
    try {
      String fileName = 'events/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time for the event.')),
      );
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create an event.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? finalBannerUrl = _existingImageUrl;
    if (_selectedImageFile != null) {
      finalBannerUrl = await _uploadImage(_selectedImageFile!);
      if (finalBannerUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed. Please try again.')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final DateTime dateTime = _selectedDateTime!;
    final String location = _locationController.text.trim();
    final String createdBy = currentUser.uid;
    
    final String organizer = _organizerController.text.trim();
    final String venue = _venueController.text.trim();
    final int maxSeats = int.tryParse(_maxSeatsController.text.trim()) ?? 0;
    final List<String> categories = _categoriesController.text.trim().split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final String? clubId = widget.isEditing ? widget.event!.clubId : null;
    final bool isNotificationEnabledDefault = widget.isEditing ? widget.event!.isNotificationEnabled : false;
    final int? maxParticipantsDefault = widget.isEditing ? widget.event!.maxParticipants : maxSeats;


    final EventService eventService = EventService();

    try {
      if (widget.isEditing && widget.event != null) {
        await eventService.updateEvent(
          eventId: widget.event!.id,
          title: title,
          description: description,
          dateTime: dateTime,
          location: location,
          clubId: clubId,
          organizer: organizer,
          bannerUrl: finalBannerUrl,
          venue: venue,
          categories: categories,
          isFree: _isEventFree,
          maxSeats: maxSeats,
          isNotificationEnabled: isNotificationEnabledDefault, 
          createdBy: createdBy, 
          maxParticipants: maxParticipantsDefault,
        );
      } else {
        await eventService.createEvent(
          title: title,
          description: description,
          dateTime: dateTime,
          location: location,
          clubId: clubId,
          organizer: organizer,
          bannerUrl: finalBannerUrl,
          venue: venue,
          categories: categories,
          isFree: _isEventFree,
          maxSeats: maxSeats,
          isNotificationEnabled: isNotificationEnabledDefault,
          createdBy: createdBy,
          maxParticipants: maxParticipantsDefault,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event ${widget.isEditing ? "updated" : "created"} successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Event' : 'Create New Event'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEvent,
              tooltip: 'Save Event',
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Event Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizerController,
                decoration: const InputDecoration(labelText: 'Organizer', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please specify the organizer' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Main Location Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue (e.g., Room 101, Main Hall)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.meeting_room_outlined)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter the venue' : null,
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Event Date & Time", style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDateTime == null
                                  ? 'Not set'
                                  : DateFormat('EEE, MMM d, yyyy - hh:mm a').format(_selectedDateTime!),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal)
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _pickDate,
                            child: Text(_selectedDateTime == null ? 'Select Date & Time' : 'Change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _maxSeatsController,
                decoration: const InputDecoration(labelText: 'Max Seats (0 for unlimited)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event_seat_outlined)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter max seats';
                  if (int.tryParse(value.trim()) == null) return 'Please enter a valid number';
                  if (int.parse(value.trim()) < 0) return 'Max seats cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoriesController,
                decoration: const InputDecoration(
                  labelText: 'Categories (comma-separated)', 
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'e.g., Tech, Workshop, Social',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is this event free?'),
                value: _isEventFree,
                onChanged: (bool value) {
                  setState(() {
                    _isEventFree = value;
                  });
                },
                secondary: Icon(_isEventFree ? Icons.money_off_csred_outlined : Icons.attach_money_outlined),
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text("Event Banner (Optional)", style: Theme.of(context).textTheme.titleSmall),
                       const SizedBox(height: 12),
                      if (_selectedImageFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(_selectedImageFile!.path),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (widget.isEditing && widget.event?.bannerUrl != null && _existingImageUrl != null) 
                         ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _existingImageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stacktrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        )
                      else 
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey[400]!)
                          ),
                          child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[600], size: 40)),
                        ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon((_existingImageUrl != null && _existingImageUrl!.isNotEmpty) || _selectedImageFile != null ? Icons.edit_outlined : Icons.add_photo_alternate_outlined),
                          label: Text((_existingImageUrl != null && _existingImageUrl!.isNotEmpty) || _selectedImageFile != null ? 'Change Banner' : 'Select Banner'),
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontWeight: FontWeight.normal)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_alt_outlined),
                label: _isLoading 
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                    : Text(widget.isEditing ? 'Update Event' : 'Create Event', style: const TextStyle(fontSize: 16)),
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
              ),
               const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
