/// Path templates and route names, in one place so no screen hardcodes a
/// route string.
abstract final class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const schemeDetail = '/schemes/:identifier';
  static const recommendations = '/recommendations';
  static const assistant = '/assistant';

  static String schemeDetailPath(String identifier) => '/schemes/$identifier';

  static String searchPath(String query) => '/search?q=${Uri.encodeQueryComponent(query)}';
}

abstract final class AppRouteNames {
  static const home = 'home';
  static const search = 'search';
  static const schemeDetail = 'schemeDetail';
  static const recommendations = 'recommendations';
  static const assistant = 'assistant';
}
