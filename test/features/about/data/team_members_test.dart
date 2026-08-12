import 'package:flutter_test/flutter_test.dart';
import 'package:ocupa2/features/about/data/team_members.dart';

void main() {
  test('el catálogo del equipo tiene 5 integrantes con datos completos', () {
    expect(TeamMembers.all, hasLength(5));

    for (final member in TeamMembers.all) {
      expect(member.name, isNotEmpty);
      expect(member.matricula, matches(RegExp(r'^\d{4}-\d{4}$')));
      expect(member.phoneDisplay, isNotEmpty);
      expect(member.phoneUri.scheme, 'tel');
      expect(member.telegramUrl.scheme, 'https');
      expect(member.telegramUrl.host, 't.me');
      expect(member.photoAsset, startsWith('assets/images/team/'));
    }
  });
}
