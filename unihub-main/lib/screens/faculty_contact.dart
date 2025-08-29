import 'package:flutter/material.dart';


class FacultyContactScreen extends StatelessWidget {
  const FacultyContactScreen({super.key});

  Widget buildContactCard(String name, String department) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(department, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(Icons.person, size: 20),
                          SizedBox(width: 8),
                          Text('Professor'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.phone, size: 20),
                          SizedBox(width: 8),
                          Text('9999999999'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.email, size: 20),
                          SizedBox(width: 8),
                          Text('Something@cloud'),
                        ],
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.black26,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Contact',style: TextStyle(
        fontFamily: 'Jersey10', // Use the custom font
        fontSize: 50, // Font size you prefer
        fontWeight: FontWeight.w300, // Font weight (regular)
      ),)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            buildContactCard('Harshitha', 'Department of Bachelor of Computer Applications'),
            buildContactCard('Ram', 'Department of Bachelor of Computer Science'),
            buildContactCard('Riya', 'Department of Bachelor of Psychology'),
          ],
        ),
      ),
    );
  }
}
