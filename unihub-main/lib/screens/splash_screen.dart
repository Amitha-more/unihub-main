import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check authentication status and navigate accordingly after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // User is not logged in, navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the column
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'UniHub',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: 90,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Campus, Your Community!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}