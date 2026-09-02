import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/recommendations/presentation/screens/recommendations_screen.dart';
import '../../features/scheme_detail/presentation/screens/scheme_detail_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter config. A [StatefulShellRoute] wraps the four nav-bar
/// destinations (Home, Search, Recommendations, Assistant) in [AppShell];
/// Scheme Detail is pushed above the shell via `parentNavigatorKey` since
/// it's reached *from* those screens, not a nav destination itself.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    errorBuilder: (context, state) => const NotFoundScreen(),
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
                path: AppRoutes.assistant,
                name: AppRouteNames.assistant,
                builder: (context, state) => const AssistantScreen(),
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
    ],
  );
});
