import 'package:edu_prediction/Routing/app_route.dart';
import 'package:edu_prediction/core/about_us.dart';
import 'package:edu_prediction/core/guidance.dart';
import 'package:edu_prediction/features/layout.dart';
import 'package:edu_prediction/signIn/signIn.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoute.onGenerateRoute,
    );
  }
}