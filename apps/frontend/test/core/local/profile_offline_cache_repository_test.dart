import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:schememedia_app/core/domain/enums.dart';
import 'package:schememedia_app/core/local/profile_offline_cache_repository.dart';
import 'package:schememedia_app/features/recommendations/domain/recommendation.dart';
import 'package:schememedia_app/features/scheme_detail/domain/scheme_detail.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const sampleRec = Recommendation(
    schemeId: 'pm-kisan-01',
    slug: 'pm-kisan-samman-nidhi',
    name: 'PM Kisan Samman Nidhi',
    category: 'Agriculture',
    jurisdiction: Jurisdiction.central,
    schemeType: SchemeType.grant,
    score: 0.95,
    verificationStatus: VerificationStatus.officiallyVerified,
    needsReview: false,
    eligibilityState: EligibilityState.pass,
    eligibilityRules: [
      EligibilityRule(
        ruleGroup: RuleGroup.all,
        attributeKey: 'is_farmer',
        operator: RuleOperator.eq,
        state: EligibilityState.pass,
        label: 'Farmer',
        explanation: 'Applicant is a practicing farmer.',
      ),
    ],
  );

  const sampleResponse = RecommendationResponse(
    query: 'farmer grants',
    profileProvided: true,
    totalReturned: 1,
    eligibilityBreakdown: {'pass': 1, 'fail': 0, 'unknown': 0},
    recommendations: [sampleRec],
  );

  test('Starts empty with isOfflineAvailable false', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileOfflineCacheRepository(prefs);

    expect(repo.isOfflineAvailable, isFalse);
    expect(repo.getCachedRecommendations(), isNull);
    expect(repo.cachedProfileLabel, isNull);
    expect(repo.lastSyncedAt, isNull);
  });

  test('Caches profile recommendations and derives profile label', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileOfflineCacheRepository(prefs);

    await repo.saveProfileRecommendations(response: sampleResponse);

    expect(repo.isOfflineAvailable, isTrue);
    expect(repo.cachedProfileLabel, 'Agriculture');
    expect(repo.lastSyncedAt, isNotNull);

    final cached = repo.getCachedRecommendations();
    expect(cached, isNotNull);
    expect(cached!.totalReturned, 1);
    expect(cached.recommendations.first.schemeId, 'pm-kisan-01');
    expect(cached.recommendations.first.name, 'PM Kisan Samman Nidhi');
  });

  test('Caches and retrieves full SchemeDetail', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileOfflineCacheRepository(prefs);

    const detail = SchemeDetail(
      schemeId: 'pm-kisan-01',
      slug: 'pm-kisan-samman-nidhi',
      name: 'PM Kisan Samman Nidhi',
      category: 'Agriculture',
      schemeType: SchemeType.grant,
      jurisdiction: Jurisdiction.central,
      descriptionShort: 'Income support of Rs. 6000 per year',
      verificationStatus: VerificationStatus.officiallyVerified,
      needsReview: false,
      tags: ['farmer', 'direct-benefit'],
      benefits: [
        Benefit(
          amountText: '₹6,000 / year',
          currency: 'INR',
          isTruncated: false,
        ),
      ],
      documents: [
        SchemeDocument(
          name: 'Aadhaar Card',
          isMandatory: true,
          needsReview: false,
        ),
      ],
      likeCount: 42,
      saveCount: 15,
      commentCount: 8,
      viewerHasLiked: true,
    );

    await repo.saveSchemeDetail(detail);

    // Retrieve by ID
    final byId = repo.getCachedSchemeDetail('pm-kisan-01');
    expect(byId, isNotNull);
    expect(byId!.name, 'PM Kisan Samman Nidhi');
    expect(byId.benefits.length, 1);
    expect(byId.documents.length, 1);
    expect(byId.documents.first.name, 'Aadhaar Card');

    // Retrieve by slug
    final bySlug = repo.getCachedSchemeDetail('pm-kisan-samman-nidhi');
    expect(bySlug, isNotNull);
    expect(bySlug!.schemeId, 'pm-kisan-01');
  });

  test('Gracefully synthesizes SchemeDetail from cached recommendation if full detail was never fetched', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileOfflineCacheRepository(prefs);

    await repo.saveProfileRecommendations(response: sampleResponse);

    // Full detail was not saved, but recommendation was saved
    final fallbackDetail = repo.getCachedSchemeDetail('pm-kisan-01');
    expect(fallbackDetail, isNotNull);
    expect(fallbackDetail!.name, 'PM Kisan Samman Nidhi');
    expect(fallbackDetail.category, 'Agriculture');
  });
}
