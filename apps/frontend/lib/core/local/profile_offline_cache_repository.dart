import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recommendations/domain/recommendation.dart';
import '../../features/scheme_detail/domain/scheme_detail.dart';
import 'saved_schemes_repository.dart';

/// Offline storage repository tailored specifically to the citizen's active profile
/// (e.g. Farmer, Student, Woman Artisan).
///
/// Rather than storing the entire 1,000 scheme database on device, this caches
/// the citizen's personalized welfare matches and their full scheme details so
/// they remain 100% accessible in rural fields, banks, and Gram Panchayats
/// with zero cellular connectivity.
class ProfileOfflineCacheRepository {
  ProfileOfflineCacheRepository([this._prefs]);

  static const _keyRecommendations = 'offline_profile_recommendations';
  static const _keyProfileLabel = 'offline_profile_label';
  static const _keySchemeDetails = 'offline_cached_scheme_details';
  static const _keyLastSynced = 'offline_last_synced_at';

  final SharedPreferences? _prefs;
  final Map<String, String> _inMemoryFallback = {};

  String? _getString(String key) => _prefs?.getString(key) ?? _inMemoryFallback[key];
  Future<void> _setString(String key, String val) async {
    _inMemoryFallback[key] = val;
    await _prefs?.setString(key, val);
  }
  bool _containsKey(String key) => (_prefs?.containsKey(key) ?? false) || _inMemoryFallback.containsKey(key);

  /// Saves the matched recommendations returned for the citizen's profile.
  Future<void> saveProfileRecommendations({
    required RecommendationResponse response,
    String? profileLabel,
  }) async {
    final jsonStr = jsonEncode(response.toJson());
    await _setString(_keyRecommendations, jsonStr);
    await _setString(_keyLastSynced, DateTime.now().toIso8601String());

    final label = profileLabel ?? _deriveProfileLabel(response);
    if (label != null) {
      await _setString(_keyProfileLabel, label);
    }
  }

  /// Retrieves the cached profile recommendations if available.
  RecommendationResponse? getCachedRecommendations() {
    final raw = _getString(_keyRecommendations);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return RecommendationResponse.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Caches a full scheme detail (benefits, documents, official URL, criteria)
  /// so it can be viewed offline.
  Future<void> saveSchemeDetail(SchemeDetail detail) async {
    final existing = _loadCachedSchemeDetailsMap();
    existing[detail.schemeId] = detail.toJson();
    existing[detail.slug] = detail.toJson();
    await _setString(_keySchemeDetails, jsonEncode(existing));
  }

  /// Retrieves full scheme detail from the local cache by id or slug.
  SchemeDetail? getCachedSchemeDetail(String identifier) {
    final map = _loadCachedSchemeDetailsMap();
    final rawJson = map[identifier];
    if (rawJson != null) {
      try {
        return SchemeDetail.fromJson(rawJson);
      } catch (_) {
        // Fall back to recommendation item conversion below
      }
    }

    // If not found as full detail, check if it was part of cached recommendations
    // and synthesize a graceful offline detail model.
    final recs = getCachedRecommendations();
    if (recs != null) {
      for (final r in recs.recommendations) {
        if (r.schemeId == identifier || r.slug == identifier) {
          return SchemeDetail(
            schemeId: r.schemeId,
            slug: r.slug,
            name: r.name,
            category: r.category,
            schemeType: r.schemeType,
            jurisdiction: r.jurisdiction,
            stateCode: r.stateCode,
            descriptionShort: r.descriptionShort,
            descriptionLong: r.descriptionShort,
            officialUrl: r.officialUrl,
            verificationStatus: r.verificationStatus,
            needsReview: r.needsReview,
            tags: const [],
            benefits: const [],
            documents: const [],
            likeCount: 0,
            saveCount: 0,
            commentCount: 0,
            viewerHasLiked: false,
          );
        }
      }
    }
    return null;
  }

  /// Checks if any offline profile schemes are cached.
  bool get isOfflineAvailable {
    return _containsKey(_keyRecommendations);
  }

  /// Profile archetype/label (e.g., "Farmer", "Student", "Rural Artisan").
  String? get cachedProfileLabel {
    return _getString(_keyProfileLabel);
  }

  /// Timestamp of the last successful online sync.
  DateTime? get lastSyncedAt {
    final raw = _getString(_keyLastSynced);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Filters cached profile recommendations by keyword match for 0ms offline search.
  List<Recommendation> searchCachedRecommendations(String query) {
    final cleanQ = query.trim().toLowerCase();
    final recs = getCachedRecommendations();
    if (recs == null || recs.recommendations.isEmpty) return const [];
    if (cleanQ.isEmpty) return recs.recommendations;
    return recs.recommendations.where((r) {
      final name = r.name.toLowerCase();
      final desc = r.descriptionShort?.toLowerCase() ?? '';
      final cat = r.category?.toLowerCase() ?? '';
      return name.contains(cleanQ) || desc.contains(cleanQ) || cat.contains(cleanQ);
    }).toList();
  }

  Map<String, dynamic> _loadCachedSchemeDetailsMap() {
    final raw = _getString(_keySchemeDetails);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return {};
    }
  }

  String? _deriveProfileLabel(RecommendationResponse response) {
    if (response.recommendations.isEmpty) return null;
    final categories = response.recommendations
        .map((r) => r.category)
        .whereType<String>()
        .toList();
    if (categories.isEmpty) return null;
    final counts = <String, int>{};
    for (final c in categories) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    var best = categories.first;
    var maxCount = 0;
    counts.forEach((cat, cnt) {
      if (cnt > maxCount) {
        maxCount = cnt;
        best = cat;
      }
    });
    return best;
  }
}

final profileOfflineCacheRepositoryProvider = Provider<ProfileOfflineCacheRepository>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    prefs = null;
  }
  return ProfileOfflineCacheRepository(prefs);
});
