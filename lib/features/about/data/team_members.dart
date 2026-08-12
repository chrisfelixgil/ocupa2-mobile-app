import 'package:ocupa2/features/about/data/models/team_member.dart';

/// Catálogo estático del equipo de desarrollo de Ocupa2.
abstract final class TeamMembers {
  static final List<TeamMember> all = <TeamMember>[
    TeamMember(
      name: 'Christian Felix Gil Castillo',
      matricula: '2012-1036',
      phoneDisplay: '829-276-5204',
      phoneUri: Uri(scheme: 'tel', path: '+18292765204'),
      telegramUrl: Uri.parse('https://t.me/+18292765204'),
      photoAsset: 'assets/images/team/Christian.jpg',
    ),
    TeamMember(
      name: 'Kaysha Lizandra Hiciano Corniel',
      matricula: '2023-1599',
      phoneDisplay: '809-778-0728',
      phoneUri: Uri(scheme: 'tel', path: '+18097780728'),
      telegramUrl: Uri.parse('https://t.me/+18097780728'),
      photoAsset: 'assets/images/team/Kaysha.jpeg',
    ),
    TeamMember(
      name: 'Ismael Polanco',
      matricula: '2021-0293',
      phoneDisplay: '829-528-3383',
      phoneUri: Uri(scheme: 'tel', path: '+18295283383'),
      telegramUrl: Uri.parse('https://t.me/+18295283383'),
      photoAsset: 'assets/images/team/Ismael.jpeg',
    ),
    TeamMember(
      name: 'Joseph Luis Cante Brito',
      matricula: '2021-1538',
      phoneDisplay: '829-616-3465',
      phoneUri: Uri(scheme: 'tel', path: '+18296163465'),
      telegramUrl: Uri.parse('https://t.me/Josephcante'),
      photoAsset: 'assets/images/team/Joseph.jpeg',
    ),
    TeamMember(
      name: 'Abisai Mora',
      matricula: '2023-0598',
      phoneDisplay: '829-880-2734',
      phoneUri: Uri(scheme: 'tel', path: '+18298802734'),
      telegramUrl: Uri.parse('https://t.me/+18298802734'),
      photoAsset: 'assets/images/team/Abisai.jpeg',
    ),
  ];
}
