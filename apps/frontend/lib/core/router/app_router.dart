import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/recommendations/presentation/screens/recommendations_screen.dart';
import '../../features/saved/presentation/screens/saved_screen.dart';
import '../../features/scheme_detail/presentation/screens/scheme_detail_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import '../local/onboarding_repository.dart';
import 'app_shell.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter config. A [StatefulShellRoute] wraps the six nav-bar
/// destinations (Home, Explore, For You, Saved, Assistant, Profile) in
/// [AppShell]; Scheme Detail/Onboarding/Login are pushed above the shell
/// via `parentNavigatorKey` since they're reached *from* those screens
/// (or, for Onboarding, before them), not nav destinations themselves.
///
/// `redirect` gates every navigation behind onboarding until
/// [hasSeenOnboardingProvider] is true (real, local `shared_preferences`
/// flag) -- `ref.read` here always reflects current state at redirect
/// time, so this doesn't need the router itself to rebuild when the flag
/// changes.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final seenOnboarding = ref.read(hasSeenOnboardingProvider);
      final goingToOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!seenOnboarding && !goingToOnboarding) return AppRoutes.onboarding;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: AppRouteNames.search,
                builder: (context, state) =>
                    SearchResultsScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recommendations,
                name: AppRouteNames.recommendations,
                builder: (context, state) => const RecommendationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                name: AppRouteNames.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assistant,
                name: AppRouteNames.assistant,
                builder: (context, state) => const AssistantScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.schemeDetail,
        name: AppRouteNames.schemeDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            SchemeDetailScreen(identifier: state.pathParameters['identifier']!),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
