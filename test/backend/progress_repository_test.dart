import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/progress/supabase_cloud_progress_repository.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('fetch parses the owned cloud row', () async {
    final api = _FakeApi()
      ..row = {'revision': 4, 'progress': SaveState.defaults().toJson()};
    final repository = SupabaseCloudProgressRepository(api: api);

    final snapshot = await repository.fetch();

    expect(snapshot?.revision, 4);
    expect(snapshot?.save.schemaVersion, SaveState.currentSchemaVersion);
  });

  test('fetch rejects unexpected response fields', () async {
    final api = _FakeApi()
      ..row = {
        'revision': 4,
        'progress': SaveState.defaults().toJson(),
        'unexpected': true,
      };

    await expectLater(
      SupabaseCloudProgressRepository(api: api).fetch(),
      throwsFormatException,
    );
  });

  test(
    'create sends no expected revision and parses created snapshot',
    () async {
      final api = _FakeApi()..responseRevision = 1;
      final repository = SupabaseCloudProgressRepository(api: api);

      final snapshot = await repository.create(SaveState.defaults());

      expect(api.lastBody?['expectedRevision'], isNull);
      expect(api.lastBody?['progress'], SaveState.defaults().toJson());
      expect(snapshot.revision, 1);
    },
  );

  test('create surfaces a server conflict snapshot', () async {
    final server = SaveState.defaults().copyWith(totalKills: 42);
    final api = _FakeApi()
      ..responseRevision = 3
      ..responseProgress = server
      ..conflict = true;
    final repository = SupabaseCloudProgressRepository(api: api);

    await expectLater(
      repository.create(SaveState.defaults()),
      throwsA(
        isA<CloudProgressConflict>().having(
          (error) => error.snapshot.save.totalKills,
          'server kills',
          42,
        ),
      ),
    );
  });

  test('update reports a server revision conflict', () async {
    final api = _FakeApi()
      ..responseRevision = 9
      ..conflict = true;
    final repository = SupabaseCloudProgressRepository(api: api);

    final result = await repository.update(
      save: SaveState.defaults(),
      expectedRevision: 7,
    );

    expect(api.lastBody?['expectedRevision'], 7);
    expect(result.hasConflict, isTrue);
    expect(result.snapshot.revision, 9);
  });

  test('sync response requires an exact boolean conflict field', () async {
    final missing = _FakeApi()..omitConflict = true;
    final malformed = _FakeApi()..rawConflict = 'false';

    await expectLater(
      SupabaseCloudProgressRepository(
        api: missing,
      ).create(SaveState.defaults()),
      throwsFormatException,
    );
    await expectLater(
      SupabaseCloudProgressRepository(
        api: _FakeApi()..includeUnexpectedField = true,
      ).create(SaveState.defaults()),
      throwsFormatException,
    );
    await expectLater(
      SupabaseCloudProgressRepository(
        api: malformed,
      ).update(save: SaveState.defaults(), expectedRevision: 1),
      throwsFormatException,
    );
  });
}

class _FakeApi implements CloudProgressApi {
  Map<String, dynamic>? row;
  Map<String, dynamic>? lastBody;
  int responseRevision = 1;
  bool conflict = false;
  bool omitConflict = false;
  Object? rawConflict;
  SaveState? responseProgress;
  bool includeUnexpectedField = false;

  @override
  Future<Map<String, dynamic>?> fetchProgress() async => row;

  @override
  Future<Map<String, dynamic>> syncProgress(Map<String, dynamic> body) async {
    lastBody = body;
    return {
      'revision': responseRevision,
      'progress': responseProgress?.toJson() ?? body['progress'],
      if (!omitConflict) 'conflict': rawConflict ?? conflict,
      if (includeUnexpectedField) 'unexpected': true,
    };
  }
}
