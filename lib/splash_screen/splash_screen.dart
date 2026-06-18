import 'package:flutter/material.dart';
import '../on_boarding/on_boarding1.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(
      const Duration(seconds: 4),
          () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Onboarding(),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "images/assets/logo.png",
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
             Text(
              "EDUPRE",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5669FF),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
