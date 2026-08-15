abstract final class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String changePassword = '/change-password';
  static const String about = '/about';

  // my_activity
  static const String activityHub = '/my-activity';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String myExperiences = '/my-activity/experiences';
  static const String myApplications = '/my-activity/applications';
  static const String myApplicationDetailPattern =
      '/my-activity/applications/:id';
  static const String myOffers = '/my-activity/offers';
  static const String applicantsListPattern =
      '/my-activity/offers/:offerId/applicants';
  static const String applicantDetailPattern =
      '/my-activity/offers/:offerId/applicants/:applicationId';
  static const String myContracts = '/my-activity/contracts';
  static const String contractDetailPattern = '/my-activity/contracts/:id';

  static String contractDetail(String id) => '/my-activity/contracts/$id';

  // job_search
  static const String jobSearchExplore = '/offers';
  static const String jobSearchMap = '/offers/map';
  static const String jobSearchOfferDetailPattern = '/offers/:id';

  static String jobSearchOfferDetail(String id) => '/offers/$id';
}
