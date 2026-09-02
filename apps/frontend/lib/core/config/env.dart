import 'package:flutter/foundation.dart';

/// Deployment environments this app can be built for. Only [Env.dev] is
/// actually used yet -- staging/prod are named here so the shape exists
/// before it's needed, not because they're wired up today.
enum Env { dev, staging, prod }

/// Environment / base-URL configuration.
///
/// No file under `core/network` or any `features/*` hardcodes a host --
/// everything reads [EnvConfig.baseUrl].
abstract final class EnvConfig {
  static const Env current = Env.dev;

  /// Resolves the API base URL.
  ///
  /// Priority:
  /// 1. `--dart-define=API_BASE_URL=...` at build time, always wins.
  /// 2. A per-platform dev default -- the Android emulator maps its host
  ///    loopback to `10.0.2.2`, not `localhost`. Every other dev target
  ///    (web, desktop, iOS simulator) reaches the host directly via
  ///    `localhost`. This is the one config detail most likely to silently
  ///    break on a real device/emulator despite working fine in a browser,
  ///    so it is resolved once, here, rather than left for each screen to
  ///    rediscover.
  ///
  /// Deliberately checks `kIsWeb` before `defaultTargetPlatform`: on web,
  /// `defaultTargetPlatform` reflects the *host OS* the browser runs on
  /// (which can itself be Android), not the deployment target, so the web
  /// branch must be decided first.
  static String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }
}
