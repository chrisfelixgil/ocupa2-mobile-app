/// AJUSTAR: valores reales que devuelve el backend para el status de una
/// oferta. El endpoint de baja es POST /offers/{id}/deactivate.
///
/// El API puede enviar `active`, `published` o omitir el campo. Solo
/// `inactive` se oculta en Mis ofertas.
enum OfferStatus { active, inactive, unknown }

OfferStatus offerStatusFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'inactive':
    case 'deactivated':
    case 'disabled':
      return OfferStatus.inactive;
    case 'active':
    case 'published':
    case 'open':
    case null:
    case '':
      return OfferStatus.active;
    default:
      return OfferStatus.active;
  }
}

bool isListedInMyOffers(OfferStatus status) {
  return status != OfferStatus.inactive;
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
