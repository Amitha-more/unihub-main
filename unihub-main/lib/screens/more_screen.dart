import 'package:flutter/material.dart';
import './faculty_contact.dart';
import 'clubs_screen.dart'; // Assuming ClubsScreen is in the same directory
import './gpa_calculator_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the list of items for clarity
    final List<Map<String, dynamic>> moreScreenItems = [
      {
        'icon': Icons.label_outline, // Using outline icons for a potentially cleaner look
        'title': 'Lost & Found',
        'onTap': () {
          // TODO: Implement navigation for Lost & Found
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => YourLostAndFoundScreen()));
        },
      },
      {
        'icon': Icons.groups_outlined,
        'title': 'Clubs',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClubsScreen()),
            ),
      },
      {
        'icon': Icons.calculate_outlined,
        'title': 'GPA Calculator',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GPACalculatorScreen()),
            ),
      },
      {
        'icon': Icons.contact_mail_outlined,
        'title': 'Faculty Contact',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FacultyContactScreen()),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white, // Ensure scaffold background is white
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'More',
          style: TextStyle(
            fontFamily: 'Jersey10', // Use the custom font
            fontSize: 50, // Font size you prefer
            color: Colors.black, // Black text for app bar title
            fontWeight: FontWeight.w300,
          ),
        ),
        backgroundColor: Colors.white, // White app bar background
        elevation: 0, // No shadow for a flatter look
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: moreScreenItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10), // Space between cards
        itemBuilder: (context, index) {
          final item = moreScreenItems[index];
          return Card(
            elevation: 2, // Slight elevation for the card
            color: Colors.white, // Card background white
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Optional: rounded corners for cards
            ),
            child: ListTile(
              leading: Icon(item['icon'] as IconData, color: Colors.black), // Black icon
              title: Text(
                item['title'] as String,
                style: const TextStyle(color: Colors.black), // Black text
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16), // Subtle trailing icon
              onTap: item['onTap'] as void Function(),
            ),
          );
        },
      ),
    );
  }
}
