class OnboardingItem {
  final String tag;
  final String title;
  final String description;

  const OnboardingItem({
    required this.tag,
    required this.title,
    required this.description,
  });
}

const List<OnboardingItem> kOnboardingItems = [
  OnboardingItem(
    tag: 'Analyse IA',
    title: 'Analysez votre peau\navec l\'IA',
    description:
        'Capturez ou importez une photo et obtenez une évaluation intelligente du risque en quelques secondes.',
  ),
  OnboardingItem(
    tag: 'Suivi continu',
    title: 'Suivez l\'évolution\ndans le temps',
    description:
        'Surveillez chaque lésion avec un suivi intelligent et recevez des alertes en cas d\'évolution préoccupante.',
  ),
  OnboardingItem(
    tag: 'Experts proches',
    title: 'Trouvez un\ndermatologue',
    description:
        'Obtenez des recommandations de spécialistes à proximité adaptées à votre niveau de risque.',
  ),
];