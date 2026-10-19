import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/auth/family_account_deletion_backend.dart';

void main() {
  const uid = 'family_123';

  group('FamilyAccountDeletionBackend local gates', () {
    test('is disabled by default without reading auth or calling transport', () async {
      var uidReads = 0;
      var calls = 0;
      final backend = FamilyAccountDeletionBackend(
        currentUid: () {
          uidReads++;
          return uid;
        },
        call: (_) async {
          calls++;
          return const {'deleted': true};
        },
      );

      await expectLater(
        backend.deleteAccount(expectedUid: uid, confirmed: true),
        throwsA(
          isA<FamilyAccountDeletionFailure>().having(
            (error) => error.issue,
            'issue',
            FamilyAccountDeletionIssue.disabled,
          ),
        ),
      );
      expect(uidReads, 0);
      expect(calls, 0);
    });

    test('refused confirmation does not read auth or call transport', () async {
      var uidReads = 0;
      var calls = 0;
      final backend = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () {
          uidReads++;
          return uid;
        },
        call: (_) async {
          calls++;
          return const {'deleted': true};
        },
      );

      await expectLater(
        backend.deleteAccount(expectedUid: uid, confirmed: false),
        throwsA(
          isA<FamilyAccountDeletionFailure>().having(
            (error) => error.issue,
            'issue',
            FamilyAccountDeletionIssue.confirmationRequired,
          ),
        ),
      );
      expect(uidReads, 0);
      expect(calls, 0);
    });

    test('missing or malformed expected UID avoids SDK transport', () async {
      var uidReads = 0;
      var calls = 0;
      final backend = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () {
          uidReads++;
          return uid;
        },
        call: (_) async {
          calls++;
          return const {'deleted': true};
        },
      );

      for (final invalidUid in ['', 'bad/uid', List.filled(129, 'x').join()]) {
        await expectLater(
          backend.deleteAccount(expectedUid: invalidUid, confirmed: true),
          throwsA(
            isA<FamilyAccountDeletionFailure>().having(
              (error) => error.issue,
              'issue',
              FamilyAccountDeletionIssue.invalidExpectedUid,
            ),
          ),
        );
      }
      expect(uidReads, 0);
      expect(calls, 0);
    });

    test('missing or mismatched current UID never calls transport', () async {
      var calls = 0;
      final backend = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () => null,
        call: (_) async {
          calls++;
          return const {'deleted': true};
        },
      );
      await expectLater(
        backend.deleteAccount(expectedUid: uid, confirmed: true),
        throwsA(
          isA<FamilyAccountDeletionFailure>().having(
            (error) => error.issue,
            'issue',
            FamilyAccountDeletionIssue.accountMismatch,
          ),
        ),
      );

      final mismatched = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () => 'another_family',
        call: (_) async {
          calls++;
          return const {'deleted': true};
        },
      );
      await expectLater(
        mismatched.deleteAccount(expectedUid: uid, confirmed: true),
        throwsA(
          isA<FamilyAccountDeletionFailure>().having(
            (error) => error.issue,
            'issue',
            FamilyAccountDeletionIssue.accountMismatch,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('UID preflight failure is typed and never calls transport', () async {
      var calls = 0;
      final backend = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () => throw StateError('raw auth detail'),
        call: (_) async {
          calls++;
          return const {'deleted': true};
        },
      );
      await expectLater(
        backend.deleteAccount(expectedUid: uid, confirmed: true),
        throwsA(
          isA<FamilyAccountDeletionFailure>().having(
            (error) => error.issue,
            'issue',
            FamilyAccountDeletionIssue.unavailable,
          ),
        ),
      );
      expect(calls, 0);
    });
  });

  group('FamilyAccountDeletionBackend callable contract', () {
    test('sends only confirmation and accepts exact deleted response', () async {
      Map<String, Object?>? sent;
      final backend = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () => uid,
        call: (data) async {
          sent = data;
          return const {'deleted': true};
        },
      );

      await backend.deleteAccount(expectedUid: uid, confirmed: true);
      expect(sent, const {'confirmDelete': true});
    });

    test('rejects malformed or ambiguous success responses', () async {
      for (final response in <Object?>[
        null,
        const {'deleted': false},
        const {'deleted': true, 'uid': uid},
        'deleted',
      ]) {
        final backend = FamilyAccountDeletionBackend(
          enabled: true,
          currentUid: () => uid,
          call: (_) async => response,
        );
        await expectLater(
          backend.deleteAccount(expectedUid: uid, confirmed: true),
          throwsA(
            isA<FamilyAccountDeletionFailure>().having(
              (error) => error.issue,
              'issue',
              FamilyAccountDeletionIssue.invalidResponse,
            ),
          ),
        );
      }
    });

    test('translates auth/App Check, precondition, input and retryable errors', () async {
      const cases = <String, FamilyAccountDeletionIssue>{
        'unauthenticated': FamilyAccountDeletionIssue.authenticationOrAppCheck,
        'permission-denied': FamilyAccountDeletionIssue.authenticationOrAppCheck,
        'failed-precondition':
            FamilyAccountDeletionIssue.recentLoginOrServerNotConfigured,
        'invalid-argument': FamilyAccountDeletionIssue.invalidRequest,
        'unavailable': FamilyAccountDeletionIssue.retryableUnavailable,
        'deadline-exceeded': FamilyAccountDeletionIssue.retryableUnavailable,
      };
      for (final entry in cases.entries) {
        final backend = FamilyAccountDeletionBackend(
          enabled: true,
          currentUid: () => uid,
          call: (_) async => throw FirebaseFunctionsException(
            code: entry.key,
            message: 'server message ignored',
          ),
        );
        await expectLater(
          backend.deleteAccount(expectedUid: uid, confirmed: true),
          throwsA(
            isA<FamilyAccountDeletionFailure>().having(
              (error) => error.issue,
              'issue',
              entry.value,
            ),
          ),
        );
      }
    });

    test('does not expose unexpected transport errors', () async {
      final backend = FamilyAccountDeletionBackend(
        enabled: true,
        currentUid: () => uid,
        call: (_) async => throw StateError('raw detail'),
      );
      await expectLater(
        backend.deleteAccount(expectedUid: uid, confirmed: true),
        throwsA(
          isA<FamilyAccountDeletionFailure>().having(
            (error) => error.issue,
            'issue',
            FamilyAccountDeletionIssue.unavailable,
          ),
        ),
      );
    });
  });
}
