class OnboardingModel {
  final String title;
  final String description;

  const OnboardingModel({required this.title, required this.description});
}

const List<OnboardingModel> onboardingPages = [
  OnboardingModel(
    title: 'Keep your health information together',
    description:
        'Store your profile, conditions, allergies, and medicines in one '
        'place — recorded by you, for you.',
  ),
  OnboardingModel(
    title: 'Stay on top of medicines and routines',
    description:
        'Track today’s doses, optional reminders, and a simple lifestyle '
        'checklist for diet, movement, sleep, and calm.',
  ),
  OnboardingModel(
    title: 'Track measurements and keep reports',
    description:
        'Record weight and blood pressure, store medical reports, and '
        'extract text on this device for you to review before saving.',
  ),
  OnboardingModel(
    title: 'You control your data',
    description:
        'Export a TARU archive, delete your health data, or delete your '
        'account. TARU helps you organize and review information you '
        'record. It does not diagnose conditions or replace professional '
        'medical care.',
  ),
];
