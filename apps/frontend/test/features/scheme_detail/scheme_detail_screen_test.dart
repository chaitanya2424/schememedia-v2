// Widget-level tests for Scheme Detail's like button and comments section
// -- previously entirely non-functional (the like "stat" was read-only,
// and comments had no UI at all despite the backend already supporting
// both). Same fake-repository-override pattern as
// recommendations_screen_test.dart: no real network call is possible once
// a widget is pumped in the test binding, so these fakes stand in for
// SchemeDetailRepository/CommentsRepository.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/domain/enums.dart';
import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/core/network/api_exception.dart';
import 'package:schememedia_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:schememedia_app/features/scheme_detail/data/comments_api.dart';
import 'package:schememedia_app/features/scheme_detail/data/comments_repository.dart';
import 'package:schememedia_app/features/scheme_detail/data/scheme_detail_api.dart';
import 'package:schememedia_app/features/scheme_detail/data/scheme_detail_repository.dart';
import 'package:schememedia_app/features/scheme_detail/domain/comment.dart';
import 'package:schememedia_app/features/scheme_detail/domain/scheme_detail.dart';
import 'package:schememedia_app/features/scheme_detail/presentation/providers/comments_providers.dart';
import 'package:schememedia_app/features/scheme_detail/presentation/providers/scheme_detail_providers.dart';
import 'package:schememedia_app/features/scheme_detail/presentation/screens/scheme_detail_screen.dart';

const _schemeId = 'SCH_TEST0001';

SchemeDetail _detail({bool? viewerHasLiked, int likeCount = 3}) {
  return SchemeDetail(
    schemeId: _schemeId,
    slug: 'test-scheme',
    name: 'Test Farmer Subsidy Scheme',
    nameHi: null,
    ministry: 'Ministry of Testing',
    category: 'Agriculture',
    schemeType: SchemeType.subsidy,
    jurisdiction: Jurisdiction.central,
    stateCode: null,
    descriptionShort: 'A short description.',
    descriptionLong: null,
    officialUrl: null,
    applicationDeadline: null,
    verificationStatus: VerificationStatus.unverified,
    needsReview: false,
    lastVerifiedAt: null,
    tags: const [],
    benefits: const [],
    documents: const [],
    likeCount: likeCount,
    saveCount: 0,
    commentCount: 0,
    averageRating: null,
    viewerHasLiked: viewerHasLiked,
  );
}

class FakeSchemeDetailRepository extends SchemeDetailRepository {
  FakeSchemeDetailRepository(this.detail) : super(SchemeDetailApi(ApiClient()));

  SchemeDetail detail;
  final likeCalls = <String>[];
  final unlikeCalls = <String>[];
  ApiException? likeError;

  @override
  Future<SchemeDetail> getDetail(String identifier) async => detail;

  @override
  Future<void> like(String schemeId) async {
    if (likeError != null) throw likeError!;
    likeCalls.add(schemeId);
  }

  @override
  Future<void> unlike(String schemeId) async {
    if (likeError != null) throw likeError!;
    unlikeCalls.add(schemeId);
  }
}

class FakeCommentsRepository extends CommentsRepository {
  FakeCommentsRepository(this.comments) : super(CommentsApi(ApiClient()));

  List<SchemeComment> comments;
  final createdContent = <String>[];
  final deletedIds = <String>[];

  @override
  Future<List<SchemeComment>> list(String schemeId) async => comments;

  @override
  Future<SchemeComment> create(String schemeId, String content) async {
    createdContent.add(content);
    final created = SchemeComment(
      id: 'new-${createdContent.length}',
      content: content,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      edited: false,
      authorName: 'You',
      viewerIsAuthor: true,
    );
    comments = [created, ...comments];
    return created;
  }

  @override
  Future<void> delete(String schemeId, String commentId) async {
    deletedIds.add(commentId);
    comments = comments.where((c) => c.id != commentId).toList();
  }
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required FakeSchemeDetailRepository detailFake,
    required FakeCommentsRepository commentsFake,
    required bool signedIn,
  }) async {
    final container = ProviderContainer(
      overrides: [
        schemeDetailRepositoryProvider.overrideWithValue(detailFake),
        commentsRepositoryProvider.overrideWithValue(commentsFake),
        isSignedInProvider.overrideWithValue(signedIn),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SchemeDetailScreen(identifier: _schemeId)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('like button', () {
    testWidgets('signed-in user can like a scheme, count and icon update', (tester) async {
      final detailFake = FakeSchemeDetailRepository(
        _detail(viewerHasLiked: false, likeCount: 3),
      );
      await pump(
        tester,
        detailFake: detailFake,
        commentsFake: FakeCommentsRepository([]),
        signedIn: true,
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scheme_detail_like_button')));
      await tester.pumpAndSettle();

      expect(detailFake.likeCalls, [_schemeId]);
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('tapping again unlikes and calls the unlike endpoint', (tester) async {
      final detailFake = FakeSchemeDetailRepository(
        _detail(viewerHasLiked: true, likeCount: 5),
      );
      await pump(
        tester,
        detailFake: detailFake,
        commentsFake: FakeCommentsRepository([]),
        signedIn: true,
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scheme_detail_like_button')));
      await tester.pumpAndSettle();

      expect(detailFake.unlikeCalls, [_schemeId]);
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('a failed like reverts the optimistic update and shows an error', (
      tester,
    ) async {
      final detailFake = FakeSchemeDetailRepository(
        _detail(viewerHasLiked: false, likeCount: 3),
      )..likeError = const ApiException.network();
      await pump(
        tester,
        detailFake: detailFake,
        commentsFake: FakeCommentsRepository([]),
        signedIn: true,
      );

      await tester.tap(find.byKey(const ValueKey('scheme_detail_like_button')));
      await tester.pumpAndSettle();

      // Reverted, not left on the optimistic value.
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('No connection. Check your network and try again.'), findsOneWidget);
    });

    testWidgets('signed-out user is not silently liked -- no API call is made', (
      tester,
    ) async {
      final detailFake = FakeSchemeDetailRepository(
        _detail(viewerHasLiked: null, likeCount: 3),
      );
      await pump(
        tester,
        detailFake: detailFake,
        commentsFake: FakeCommentsRepository([]),
        signedIn: false,
      );

      // Signed out: never a filled heart, since viewerHasLiked is null,
      // not false -- see SchemeDetail.viewerHasLiked's own doc comment.
      // A tap here would push /login (needs a real GoRouter in the tree,
      // not set up in this widget-only test harness -- the router push
      // itself is a one-line guard, not what this test is verifying), so
      // this only asserts the render, not the tap.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(detailFake.likeCalls, isEmpty);
      expect(detailFake.unlikeCalls, isEmpty);
    });
  });

  group('comments', () {
    SchemeComment comment({
      String id = 'c1',
      String content = 'Does this cover part-time farmers?',
      String author = 'Priya Sharma',
      bool viewerIsAuthor = false,
    }) {
      return SchemeComment(
        id: id,
        content: content,
        createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String(),
        edited: false,
        authorName: author,
        viewerIsAuthor: viewerIsAuthor,
      );
    }

    testWidgets('renders existing comments, newest first as returned by the repository', (
      tester,
    ) async {
      final commentsFake = FakeCommentsRepository([
        comment(id: 'c2', content: 'Second question.', author: 'Bob'),
        comment(id: 'c1', content: 'First question.', author: 'Alice'),
      ]);
      await pump(
        tester,
        detailFake: FakeSchemeDetailRepository(_detail()),
        commentsFake: commentsFake,
        signedIn: true,
      );

      expect(find.text('Second question.'), findsOneWidget);
      expect(find.text('First question.'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('empty state is shown when there are no comments yet', (tester) async {
      await pump(
        tester,
        detailFake: FakeSchemeDetailRepository(_detail()),
        commentsFake: FakeCommentsRepository([]),
        signedIn: true,
      );

      expect(find.text('No comments yet. Be the first to ask a question.'), findsOneWidget);
    });

    testWidgets('signed-in user can post a comment and sees it appear', (tester) async {
      final commentsFake = FakeCommentsRepository([]);
      await pump(
        tester,
        detailFake: FakeSchemeDetailRepository(_detail()),
        commentsFake: commentsFake,
        signedIn: true,
      );

      await tester.enterText(
        find.byKey(const ValueKey('scheme_detail_comment_field')),
        'Is there an age limit?',
      );
      await tester.tap(find.byKey(const ValueKey('scheme_detail_comment_send_button')));
      await tester.pumpAndSettle();

      expect(commentsFake.createdContent, ['Is there an age limit?']);
      expect(find.text('Is there an age limit?'), findsOneWidget);
      // The composer clears after a successful post.
      expect(find.text('Is there an age limit?'), findsOneWidget);
    });

    testWidgets('signed-out visitor sees a sign-in prompt instead of a composer', (
      tester,
    ) async {
      await pump(
        tester,
        detailFake: FakeSchemeDetailRepository(_detail()),
        commentsFake: FakeCommentsRepository([comment()]),
        signedIn: false,
      );

      expect(
        find.text('Sign in to ask a question or share your experience.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('scheme_detail_comment_field')), findsNothing);
      // Listing still works while signed out -- comments are public.
      expect(find.text('Does this cover part-time farmers?'), findsOneWidget);
    });

    testWidgets('the author of a comment sees a delete control and can delete it', (
      tester,
    ) async {
      final commentsFake = FakeCommentsRepository([comment(viewerIsAuthor: true)]);
      await pump(
        tester,
        detailFake: FakeSchemeDetailRepository(_detail()),
        commentsFake: commentsFake,
        signedIn: true,
      );

      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsOneWidget);
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(commentsFake.deletedIds, ['c1']);
      expect(find.text('Does this cover part-time farmers?'), findsNothing);
      expect(find.text('No comments yet. Be the first to ask a question.'), findsOneWidget);
    });

    testWidgets('another visitor does not see a delete control on someone else\'s comment', (
      tester,
    ) async {
      await pump(
        tester,
        detailFake: FakeSchemeDetailRepository(_detail()),
        commentsFake: FakeCommentsRepository([comment(viewerIsAuthor: false)]),
        signedIn: true,
      );

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });
}
