import 'package:flutter/material.dart';
import 'package:task_manager/screens/login_screen.dart';

/// Represents the landing screen of the app.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  /// Builds the UI for the landing screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display the Flutter logo
            const FlutterLogo(size: 200),
            // Button to navigate to the login screen
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                  return const LoginScreen();
                }));
              },
              child: const Text('Enter'),
            ),
          ],
        ),
      ),
    );
  }
}
