abstract final class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';

  static const String me = '/me';
  static const String changePassword = '/me/password';

  static const String uploads = '/uploads';
  static const String jobTypes = '/job-types';

  static const String offers = '/offers';

  static String offerDetail(String id) => '/offers/$id';

  static String applyToOffer(String id) => '/offers/$id/apply';
}
