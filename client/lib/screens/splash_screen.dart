import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match the splash image background
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: Colors.black),
            child: Image.asset(
              'lib/assets/images/splash_screen.png',
              fit: BoxFit.contain, // Changed from cover to contain
            ),
          ),
        ),
      ),
    );
  }
}
