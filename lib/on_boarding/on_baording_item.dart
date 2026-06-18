import 'package:flutter/material.dart';
import 'on_boarding_model.dart';

class OnboardingItem extends StatelessWidget {
  final OnboardingModel onboardingModel;

  const OnboardingItem({super.key, required this.onboardingModel});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            onboardingModel.imagePath,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              onboardingModel.title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),

    );
  }
}
