abstract final class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';

  static const String me = '/me';
  static const String completeProfile = '/me/profile';
  static const String changePassword = '/me/password';

  static const String uploads = '/uploads';
  static const String jobTypes = '/job-types';
  static const String myExperiences = '/me/experiences';

  static String experienceById(String id) => '/me/experiences/$id';

  static const String myApplications = '/me/applications';
  static String applicationById(String id) => '/applications/$id';

  static const String myContracts = '/me/contracts';
  static String contractDetail(String id) => '/contracts/$id';
  static String contractTerms(String id) => '/contracts/$id/terms';
  static String contractAccept(String id) => '/contracts/$id/accept';
  static String contractReject(String id) => '/contracts/$id/reject';
  static String contractComments(String id) => '/contracts/$id/comments';
  static String contractPhotos(String id) => '/contracts/$id/photos';
  static String contractCancel(String id) => '/contracts/$id/cancel';

  static const String offers = '/offers';

  static String offerDetail(String id) => '/offers/$id';

  static String applyToOffer(String id) => '/offers/$id/apply';
}
