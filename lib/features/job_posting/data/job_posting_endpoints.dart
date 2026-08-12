/// Endpoints propios de "Publicación de ofertas".
///
/// Se definen aquí (y no en core/constants/api_endpoints.dart) para no tocar
/// un archivo que puede ser de otro miembro del equipo. Si el proyecto ya
/// tiene una convención central de endpoints, mueve estas constantes ahí.
class JobPostingEndpoints {
  static const offers = '/offers';
  static const myOffers = '/me/offers';

  static String offerById(String id) => '/offers/$id';

  static String deactivateOffer(String id) => '/offers/$id/deactivate';
}
