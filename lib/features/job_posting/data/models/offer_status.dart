/// AJUSTAR: valores reales que devuelve el backend para el status de una
/// oferta. Se asumen 'active' / 'inactive' porque el endpoint expuesto es
/// POST /offers/{id}/deactivate.
enum OfferStatus { active, inactive, unknown }

OfferStatus offerStatusFromString(String? value) {
  switch (value) {
    case 'active':
      return OfferStatus.active;
    case 'inactive':
      return OfferStatus.inactive;
    default:
      return OfferStatus.unknown;
  }
}

extension OfferStatusX on OfferStatus {
  String get label {
    switch (this) {
      case OfferStatus.active:
        return 'Activa';
      case OfferStatus.inactive:
        return 'Inactiva';
      case OfferStatus.unknown:
        return 'Activa';
    }
  }
}
