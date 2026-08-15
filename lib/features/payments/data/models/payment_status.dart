enum PaymentStatus { pending, completed, failed, unknown }

PaymentStatus paymentStatusFromString(String? value) {
  switch (value) {
    case 'pending':
      return PaymentStatus.pending;
    case 'approved':
    case 'completed':
    case 'success':
      return PaymentStatus.completed;
    case 'declined':
    case 'rejected':
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
        return 'Aprobado';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.unknown:
        return 'Desconocido';
    }
  }
}