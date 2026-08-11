class TeamMember {
  const TeamMember({
    required this.name,
    required this.matricula,
    required this.phoneDisplay,
    required this.phoneUri,
    required this.telegramUrl,
    required this.photoAsset,
  });

  final String name;
  final String matricula;
  final String phoneDisplay;
  final Uri phoneUri;
  final Uri telegramUrl;
  final String photoAsset;
}
