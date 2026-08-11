abstract final class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String changePassword = '/change-password';

  // job_search
  static const String jobSearchExplore = '/offers';
  static const String jobSearchMap = '/offers/map';
  static const String jobSearchOfferDetailPattern = '/offers/:id';

  static String jobSearchOfferDetail(String id) => '/offers/$id';
}
