class AppConstants {
  // App Info
  static const String appName = 'UniHUB';
  static const String appTagline = 'Your Campus, Your Community!';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String clubsCollection = 'clubs';
  static const String lostFoundCollection = 'lost_found';
  static const String notesCollection = 'notes';

  // Event Categories
  static const List<String> eventCategories = [
    'All',
    'Tech',
    'Cultural',
    'Sports',
    'Workshop',
    'Academic',
    'Social',
    'Other'
  ];

  // Club Categories
  static const List<String> clubCategories = [
    'Technical',
    'Cultural',
    'Sports',
    'Social',
    'Academic',
    'Professional'
  ];

  // Academic Years
  static const List<int> academicYears = [1, 2, 3, 4];

  // Branches
  static const List<String> branches = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Civil',
    'Chemical',
    'Other'
  ];

  // Image Upload Paths
  static const String profilePicsPath = 'profile_pics';
  static const String eventBannersPath = 'event_banners';
  static const String clubLogosPath = 'club_logos';
  static const String lostFoundImagesPath = 'lost_found_images';
  static const String notesPath = 'notes';

  // File Upload Limits (in MB)
  static const int maxImageSize = 5;
  static const int maxNoteSize = 10;

  // Notification Channels
  static const String eventChannelId = 'events_channel';
  static const String eventChannelName = 'Events';
  static const String eventChannelDescription = 'Notifications for events';

  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String unknownError = 'An unknown error occurred';
  static const String authError = 'Authentication failed';
  static const String uploadError = 'Failed to upload file';
  static const String downloadError = 'Failed to download file';
  static const String permissionError = 'Permission denied';

  // Success Messages
  static const String profileUpdated = 'Profile updated successfully';
  static const String eventCreated = 'Event created successfully';
  static const String eventRegistered = 'Successfully registered for event';
  static const String clubJoined = 'Successfully joined club';
  static const String noteUploaded = 'Note uploaded successfully';
  static const String itemPosted = 'Item posted successfully';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxBioLength = 150;

  // Time Formats
  static const String dateFormat = 'MMM d, y';
  static const String timeFormat = 'h:mm a';
  static const String dateTimeFormat = 'MMM d, y • h:mm a';

  // UI Constants
  static const double appBarHeight = 56.0;
  static const double bottomNavBarHeight = 60.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double inputBorderRadius = 8.0;
  static const double avatarRadius = 20.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
} 