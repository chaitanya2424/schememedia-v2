import 'package:dio/dio.dart';

import '../../../core/domain/enums.dart';
import '../../../core/local/saved_schemes_repository.dart' show SavedScheme;
import '../../../core/network/api_exception.dart';
import 'saved_schemes_api.dart';

/// The account-backed counterpart to SavedSchemesRepository (core/local) --
/// same [SavedScheme] shape (so `SavedSchemesNotifier` can hold either
/// source interchangeably), backed by `/me/saved-schemes` instead of
/// `shared_preferences`.
class SavedSchemesRemoteRepository {
  SavedSchemesRemoteRepository(this._api);

  final SavedSchemesApi _api;

  Future<Map<String, SavedScheme>> list() async {
    try {
      final rows = await _api.list();
      return {
        for (final row in rows)
          row['scheme_id'] as String: SavedScheme(
            schemeId: row['scheme_id'] as String,
            name: row['name'] as String,
            category: row['category'] as String?,
            description: row['description_short'] as String?,
            verificationStatus: const VerificationStatusConverter().fromJson(
              row['verification_status'] as String,
            ),
            needsReview: row['needs_review'] as bool,
          ),
      };
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<void> save(SavedScheme scheme) async {
    try {
      await _api.save(scheme.schemeId);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<void> unsave(String schemeId) async {
    try {
      await _api.unsave(schemeId);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
