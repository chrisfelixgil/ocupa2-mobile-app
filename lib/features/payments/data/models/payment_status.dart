/// AJUSTAR: valores reales que devuelve el backend para el status de pago.
/// Se asumen porque el endpoint es un "cobro simulado".
enum PaymentStatus { pending, completed, failed, unknown }

PaymentStatus paymentStatusFromString(String? value) {
  switch (value) {
    case 'pending':
      return PaymentStatus.pending;
    case 'completed':
    case 'success':
      return PaymentStatus.completed;
    case 'failed':
      return PaymentStatus.failed;
    default:
      return PaymentStatus.unknown;
  }
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.unknown:
        return 'Desconocido';
    }
  }
}
