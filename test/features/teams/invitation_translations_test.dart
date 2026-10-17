import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads the shipped translation file rather than any build-time fragment, so
/// the test exercises exactly what the app loads and passes on a fresh clone.
void main() {
  group('invitations translations', () {
    late Set<String> englishKeys;
    late Set<String> malayKeys;

    setUpAll(() {
      englishKeys = _invitationKeys('en');
      malayKeys = _invitationKeys('ms');
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

/// Flattens the `invitations` namespace of the shipped translation file,
/// keeping the namespace prefix so paths match the keys the flow uses.
Set<String> _invitationKeys(String languageCode) {
  final file = File('assets/translations/$languageCode.json');
  final all = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final invitations = all['invitations'];
  if (invitations is! Map<String, dynamic>) {
    fail(
      'assets/translations/$languageCode.json has no "invitations" namespace',
    );
  }
  return _flattenKeys(invitations, 'invitations');
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
