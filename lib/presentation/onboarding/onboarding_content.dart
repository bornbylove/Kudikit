class OnboardingContent {
  final String imagePath;
  final String title;
  final String subtitle;

  const OnboardingContent({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

final List<OnboardingContent> onboardingContents = [
  const OnboardingContent(
    imagePath: 'assets/images/benefit_3.png',
    title: 'Pay bills, send money, and manage your finances',
    subtitle: 'Send money in seconds. No stress, no delays, no hidden charges.',
  ),
  const OnboardingContent(
    imagePath: 'assets/images/benefit_2.png',
    title: 'Send and receive cash from a Kudikit Tribe member closest to you',
    subtitle:
        'Every Tribe member is verified. Send and receive with people you can actually trust.',
  ),
  const OnboardingContent(
    imagePath: 'assets/images/benefit_1.png',
    title: 'Earn rewards with every transaction you make!',
    subtitle:
        'Every payment puts money back in your pocket. No points, no waiting — real cashback, instantly.',
  ),
];
