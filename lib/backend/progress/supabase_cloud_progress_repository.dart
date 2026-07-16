import 'package:supabase_flutter/supabase_flutter.dart';

import '../../game/systems/save_system.dart';
import 'cloud_progress_repository.dart';
import 'save_state_validator.dart';

abstract interface class CloudProgressApi {
  Future<Map<String, dynamic>?> fetchProgress();
  Future<Map<String, dynamic>> syncProgress(Map<String, dynamic> body);
}

class SupabaseCloudProgressRepository implements CloudProgressRepository {
  SupabaseCloudProgressRepository({
    CloudProgressApi? api,
    SaveStateValidator? validator,
  }) : _api = api ?? _SupabaseCloudProgressApi(Supabase.instance.client),
       _validator = validator ?? SaveStateValidator();

  final CloudProgressApi _api;
  final SaveStateValidator _validator;

  @override
  Future<CloudProgressSnapshot?> fetch() async {
    final row = await _api.fetchProgress();
    return row == null ? null : _snapshot(row);
  }

  @override
  Future<CloudProgressSnapshot> create(SaveState save) async {
    _validator.validate(save);
    return _snapshot(
      await _api.syncProgress({
        'schemaVersion': save.schemaVersion,
        'progress': save.toJson(),
        'expectedRevision': null,
      }),
    );
  }

  @override
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  }) async {
    _validator.validate(save);
    final response = await _api.syncProgress({
      'schemaVersion': save.schemaVersion,
      'progress': save.toJson(),
      'expectedRevision': expectedRevision,
    });
    final snapshot = _snapshot(response);
    return response['conflict'] == true
        ? CloudSyncResult.conflict(snapshot)
        : CloudSyncResult.updated(snapshot);
  }

  CloudProgressSnapshot _snapshot(Map<String, dynamic> json) {
    final revision = json['revision'];
    final rawProgress = json['progress'];
    if (revision is! int || rawProgress is! Map) {
      throw const FormatException('Invalid cloud progress response');
    }
    final progress = Map<String, dynamic>.from(rawProgress);
    _validator.validateJson(progress);
    return CloudProgressSnapshot(
      revision: revision,
      save: SaveState.fromJson(progress),
    );
  }
}

class _SupabaseCloudProgressApi implements CloudProgressApi {
  _SupabaseCloudProgressApi(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchProgress() async {
    final row = await _client
        .from('player_progress')
        .select('revision, progress')
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> syncProgress(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(
      'sync-progress',
      body: body,
    );
    if (response.status < 200 ||
        response.status >= 300 ||
        response.data is! Map) {
      throw StateError('Cloud progress sync failed (${response.status})');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}
