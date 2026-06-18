class OnboardingModel {
  final String imagePath;
  final String title;

  OnboardingModel({
    required this.imagePath,
    required this.title,
  });

  static List<OnboardingModel> OnboardingList = [
    OnboardingModel(
      imagePath: "images/assets/onboarding1.png",
      title: "Welcome to EduPre",
    ),
    OnboardingModel(
      imagePath: "images/assets/onboarding2.png",
      title: "Discover Your Learning Journey",

    ),
    OnboardingModel(
      imagePath: "images/assets/onboarding3.png",
      title: "Achieve Your Dreams with EduPre",

    ),
  ];
}
