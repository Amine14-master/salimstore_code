import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match the splash image background
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Colors.white),
          child: Transform.scale(
            scale: 1.3,
            child: Image.asset(
              'lib/assets/images/splash_screen.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
