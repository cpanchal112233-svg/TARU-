class OnboardingModel {
  final String title;
  final String description;
  final String image;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.image,
  });
}

const List<OnboardingModel> onboardingPages = [
  OnboardingModel(
    title: "Welcome to TARU",
    description:
        "Your AI-powered health companion that helps you understand and improve your health journey.",
    image: "assets/images/onboarding1.png",
  ),

  OnboardingModel(
    title: "Understand Your Reports",
    description:
        "Upload medical reports and receive clear explanations with personalized insights.",
    image: "assets/images/onboarding2.png",
  ),

  OnboardingModel(
    title: "Daily Health Routine",
    description:
        "Receive personalized medication reminders, diet plans, exercise, sleep, and mindfulness guidance.",
    image: "assets/images/onboarding3.png",
  ),

  OnboardingModel(
    title: "Track Your Progress",
    description:
        "Monitor improvements and build healthy habits with AI-powered recommendations.",
    image: "assets/images/onboarding4.png",
  ),
];
