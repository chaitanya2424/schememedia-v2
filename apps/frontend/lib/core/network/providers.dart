import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// The root of every feature's provider graph -- swappable in tests via
/// `ProviderScope(overrides: [dioProvider.overrideWithValue(...)])` (or
/// `apiClientProvider` directly) instead of hitting a real network.
final dioProvider = Provider<Dio>((ref) => ApiClient.buildDio());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(dio: ref.watch(dioProvider)));
