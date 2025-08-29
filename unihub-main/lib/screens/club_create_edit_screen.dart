import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/club.dart';
import '../services/club_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ClubCreateEditScreen extends StatefulWidget {
  final Club? club;

  const ClubCreateEditScreen({Key? key, this.club}) : super(key: key);

  @override
  State<ClubCreateEditScreen> createState() => _ClubCreateEditScreenState();
}

class _ClubCreateEditScreenState extends State<ClubCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  final ClubService _clubService = ClubService();

  bool get _isEditMode => widget.club != null;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_isEditMode && widget.club != null) {
      _nameController.text = widget.club!.name;
      _descriptionController.text = widget.club!.description;
      _categoryController.text = widget.club!.category;
      _logoUrlController.text = widget.club!.logoUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentUserId == null) {
      setState(() => _error = 'You must be logged in.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clubData = Club(
        id: _isEditMode ? widget.club!.id : '', // Service generates ID for new
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isNotEmpty ? _logoUrlController.text.trim() : null,
        category: _categoryController.text.trim(),
        members: _isEditMode ? widget.club!.members : [_currentUserId!],
        admins: _isEditMode ? widget.club!.admins : [_currentUserId!], // <<<< Use widget.club!.admins
        joinRequests: _isEditMode ? widget.club!.joinRequests : [],
        createdAt: _isEditMode ? widget.club!.createdAt : DateTime.now(),
      );

      if (_isEditMode) {
        // <<<< Check against widget.club!.admins
        if (!widget.club!.admins.contains(_currentUserId!)) {
          throw Exception('You do not have permission to edit this club.');
        }
        await _clubService.updateClub(clubData);
        if (mounted) Navigator.of(context).pop(clubData);
      } else {
        String newClubId = await _clubService.createClub(clubData);
        if (mounted) Navigator.of(context).pop(clubData.copyWith(id: newClubId));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canPerformAction = false;
    if (_isEditMode) {
      canPerformAction = widget.club != null &&
          _currentUserId != null &&
          widget.club!.admins.contains(_currentUserId!); // <<<< Check widget.club!.admins
    } else {
      canPerformAction = _currentUserId != null;
    }

    String screenTitle = _isEditMode ? 'Edit Club' : 'Create New Club';
    String buttonText = _isEditMode ? 'Save Changes' : 'Create Club';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Club Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.group_work)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                enabled: canPerformAction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                enabled: canPerformAction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                enabled: canPerformAction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logoUrlController,
                decoration: const InputDecoration(labelText: 'Logo URL (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image)),
                keyboardType: TextInputType.url,
                enabled: canPerformAction,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                ),
              if (!canPerformAction && _currentUserId != null && _isEditMode)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Only administrators can edit this club.', style: TextStyle(color: Theme.of(context).colorScheme.error.withOpacity(0.8)), textAlign: TextAlign.center),
                ),
              if (_currentUserId == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('You need to be logged in.', style: TextStyle(color: Theme.of(context).colorScheme.error.withOpacity(0.8)), textAlign: TextAlign.center),
                ),
              if (canPerformAction)
                ElevatedButton.icon(
                  icon: Icon(_isEditMode ? Icons.save_alt_outlined : Icons.add_circle_outline),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  label: Text(buttonText),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
