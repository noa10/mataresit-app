import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `invitations` fragments are merged into `assets/translations/*.json` by
/// hand, so they must keep identical key sets.
void main() {
  group('invitations translation fragments', () {
    late Set<String> englishKeys;
    late Set<String> malayKeys;

    setUpAll(() {
      englishKeys = _flattenKeys(_read('en'));
      malayKeys = _flattenKeys(_read('ms'));
    });

    test('declare the same keys in English and Malay', () {
      expect(malayKeys.difference(englishKeys), isEmpty);
      expect(englishKeys.difference(malayKeys), isEmpty);
      expect(englishKeys, isNotEmpty);
    });

    test('declare every key the acceptance flow uses', () {
      const usedKeys = {
        'invitations.title',
        'invitations.loading',
        'invitations.accept',
        'invitations.accepted',
        'invitations.alreadyMember',
        'invitations.goToTeams',
        'invitations.signInToAccept',
        'invitations.createAccountToAccept',
        'invitations.signInWithDifferentAccount',
        'invitations.signedInAs',
        'invitations.retry',
        'invitations.forEmail',
        'invitations.invitedBy',
        'invitations.expiresAt',
        'invitations.message',
        'invitations.unknownTeam',
        'invitations.crossTeam.message',
        'invitations.loggedOut.message',
        'invitations.unregistered.message',
        'invitations.unknownState.title',
        'invitations.unknownState.message',
        'invitations.errors.title',
        'invitations.errors.expiredTitle',
        'invitations.errors.notFoundTitle',
        'invitations.errors.expired',
        'invitations.errors.notFound',
        'invitations.errors.generic',
        'invitations.reasons.alreadyMember',
        'invitations.reasons.emailMismatch',
        'invitations.reasons.invalid',
        'invitations.reasons.generic',
        'invitations.roles.owner',
        'invitations.roles.admin',
        'invitations.roles.member',
        'invitations.roles.viewer',
      };

      expect(
        englishKeys.containsAll(usedKeys),
        isTrue,
        reason: 'missing: ${usedKeys.difference(englishKeys)}',
      );
    });
  });
}

Map<String, dynamic> _read(String languageCode) {
  final file = File('.omc/i18n/invitations.$languageCode.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _flattenKeys(Map<String, dynamic> json, [String prefix = '']) {
  final keys = <String>{};
  json.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(value, path));
    } else {
      keys.add(path);
    }
  });
  return keys;
}
