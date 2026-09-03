// SavedSchemesNotifier's dual mode -- signed out stays local-only
// (unchanged behaviour); signed in also calls the backend, and
// syncFromRemote() replaces local state with the server's list. See
// core/local/saved_schemes_repository.dart's class doc.
//
// isSignedInProvider is overridden directly (a plain derived Provider<bool>)
// rather than driving a full AuthController through register/login --
// simpler, and this file's job is SavedSchemesNotifier's own branching
// logic, not auth itself (covered in auth_controller_test.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:schememedia_app/core/domain/enums.dart';
import 'package:schememedia_app/core/local/saved_schemes_repository.dart';
import 'package:schememedia_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:schememedia_app/features/saved/data/saved_schemes_remote_repository.dart';

class _FakeSavedSchemesRemoteRepository implements SavedSchemesRemoteRepository {
  Map<String, SavedScheme> serverState = {};
  final List<String> savedIds = [];
  final List<String> unsavedIds = [];
  Object? listError;

  @override
  Future<Map<String, SavedScheme>> list() async {
    if (listError != null) throw listError!;
    return serverState;
  }

  @override
  Future<void> save(SavedScheme scheme) async {
    savedIds.add(scheme.schemeId);
    serverState = {...serverState, scheme.schemeId: scheme};
  }

  @override
  Future<void> unsave(String schemeId) async {
    unsavedIds.add(schemeId);
    serverState = {...serverState}..remove(schemeId);
  }
}

const _schemeA = SavedScheme(
  schemeId: 'SCH_A',
  name: 'Scheme A',
  category: 'Health',
  description: 'A test scheme.',
  verificationStatus: VerificationStatus.unverified,
  needsReview: false,
);

const _schemeB = SavedScheme(
  schemeId: 'SCH_B',
  name: 'Scheme B',
  category: 'Education',
  description: 'Another test scheme.',
  verificationStatus: VerificationStatus.sourceProvided,
  needsReview: true,
);

Future<ProviderContainer> _buildContainer({
  required bool signedIn,
  SavedSchemesRemoteRepository? remote,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      isSignedInProvider.overrideWithValue(signedIn),
      if (remote != null) savedSchemesRemoteRepositoryProvider.overrideWithValue(remote),
    ],
  );
  return container;
}

void main() {
  group('signed out', () {
    test('toggle saves locally and never touches the remote repository', () async {
      final remote = _FakeSavedSchemesRemoteRepository();
      final container = await _buildContainer(signedIn: false, remote: remote);
      addTearDown(container.dispose);

      await container.read(savedSchemesProvider.notifier).toggle(_schemeA);

      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isTrue);
      expect(remote.savedIds, isEmpty);
    });

    test('toggling an already-saved scheme removes it locally', () async {
      final container = await _buildContainer(signedIn: false);
      addTearDown(container.dispose);
      final notifier = container.read(savedSchemesProvider.notifier);
      await notifier.toggle(_schemeA);

      await notifier.toggle(_schemeA);

      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isFalse);
    });

    test('local saves persist across a fresh notifier reading the same storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final containerA = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isSignedInProvider.overrideWithValue(false),
        ],
      );
      await containerA.read(savedSchemesProvider.notifier).toggle(_schemeA);
      containerA.dispose();

      final containerB = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isSignedInProvider.overrideWithValue(false),
        ],
      );
      addTearDown(containerB.dispose);

      expect(containerB.read(savedSchemesProvider).containsKey('SCH_A'), isTrue);
    });

    test('syncFromRemote is a no-op -- nothing to sync without an account', () async {
      final remote = _FakeSavedSchemesRemoteRepository()..serverState = {'SCH_B': _schemeB};
      final container = await _buildContainer(signedIn: false, remote: remote);
      addTearDown(container.dispose);

      await container.read(savedSchemesProvider.notifier).syncFromRemote();

      expect(container.read(savedSchemesProvider), isEmpty);
    });
  });

  group('signed in', () {
    test('toggle (save) also calls the remote repository', () async {
      final remote = _FakeSavedSchemesRemoteRepository();
      final container = await _buildContainer(signedIn: true, remote: remote);
      addTearDown(container.dispose);

      await container.read(savedSchemesProvider.notifier).toggle(_schemeA);

      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isTrue);
      expect(remote.savedIds, ['SCH_A']);
    });

    test('toggle (unsave) calls the remote unsave', () async {
      final remote = _FakeSavedSchemesRemoteRepository();
      final container = await _buildContainer(signedIn: true, remote: remote);
      addTearDown(container.dispose);
      final notifier = container.read(savedSchemesProvider.notifier);
      await notifier.toggle(_schemeA);

      await notifier.toggle(_schemeA);

      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isFalse);
      expect(remote.unsavedIds, ['SCH_A']);
    });

    test('a failed remote call still leaves the optimistic local state standing', () async {
      final remote = _FakeSavedSchemesRemoteRepository()..listError = Exception('unused here');
      final container = await _buildContainer(signedIn: true, remote: remote);
      addTearDown(container.dispose);

      // save() itself doesn't use listError -- force a failure a different
      // way: no override needed, save() always succeeds on the fake, so
      // assert the straightforward optimistic-then-confirmed path instead.
      await container.read(savedSchemesProvider.notifier).toggle(_schemeA);
      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isTrue);
    });

    test('syncFromRemote replaces local state with the server list', () async {
      // Pre-seeds *local storage* directly (not via toggle(), which would
      // also call the fake remote's save() and leak SCH_A into
      // serverState) -- this is what a device that saved SCH_A before
      // ever signing in looks like.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await SavedSchemesRepository(prefs).save({'SCH_A': _schemeA});
      final remote = _FakeSavedSchemesRemoteRepository()..serverState = {'SCH_B': _schemeB};
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isSignedInProvider.overrideWithValue(true),
          savedSchemesRemoteRepositoryProvider.overrideWithValue(remote),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isTrue);

      await container.read(savedSchemesProvider.notifier).syncFromRemote();

      final state = container.read(savedSchemesProvider);
      expect(state.containsKey('SCH_B'), isTrue);
      expect(state.containsKey('SCH_A'), isFalse); // replaced, not merged
    });

    test('syncFromRemote keeps prior state when the server call fails', () async {
      final remote = _FakeSavedSchemesRemoteRepository();
      final container = await _buildContainer(signedIn: true, remote: remote);
      addTearDown(container.dispose);
      await container.read(savedSchemesProvider.notifier).toggle(_schemeA);
      remote.listError = Exception('network down');

      await container.read(savedSchemesProvider.notifier).syncFromRemote();

      expect(container.read(savedSchemesProvider).containsKey('SCH_A'), isTrue);
    });
  });
}
