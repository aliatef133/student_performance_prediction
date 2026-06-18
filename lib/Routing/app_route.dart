import 'package:edu_prediction/Routing/page_route.dart';
import 'package:flutter/material.dart';
import '../features/layout.dart';
import '../features/layout.dart';
import '../on_boarding/on_boarding1.dart';
import '../signIn/signIn.dart';
import '../splash_screen/splash_screen.dart';

abstract class AppRoute {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case PageRouteName.initial:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
          settings: settings,
        );

      case PageRouteName.onBoarding:
        return MaterialPageRoute(
          builder: (context) => const Onboarding(),
          settings: settings,
        );

      case PageRouteName.signIn:
        return MaterialPageRoute(
          builder: (context) => const SignIn(),
          settings: settings,
        );

      case PageRouteName.layOut:
        return MaterialPageRoute(
          builder: (context) => const Layout(title: '', previousAnswers: {}, token: '',),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
    }
  }
}
