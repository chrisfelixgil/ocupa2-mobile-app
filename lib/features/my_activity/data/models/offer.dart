/// Modelo para ofertas publicadas por el usuario (GET /me/offers).
class Offer {
  const Offer({
    required this.id,
    required this.jobTypeName,
    required this.address,
    required this.status,
    this.photo,
    this.description,
    this.contractType,
    this.payment,
    this.deadline,
    this.questions = const [],
    this.applicantsCount = 0,
    this.likesCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String jobTypeName;
  final String address;
  final OfferStatus status;
  final String? photo;
  final String? description;
  final String? contractType;
  final Payment? payment;
  final DateTime? deadline;
  final List<Question> questions;
  final int applicantsCount;
  final int likesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == OfferStatus.published;

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? json['_id'] ?? '',
      jobTypeName: json['jobTypeName'] ?? json['jobTypeKey'] ?? 'Oferta',
      address: json['address'] ?? '',
      status: OfferStatus.fromString(json['status'] as String? ?? 'published'),
      photo: json['photo'] ?? json['photoUrl'],
      description: json['description'],
      contractType: json['contractType'],
      payment: json['payment'] != null
          ? Payment.fromJson(json['payment'])
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      questions: (json['questions'] as List? ?? [])
          .map((q) => Question.fromJson(q))
          .toList(),
      applicantsCount: json['applicantsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

/// Enum para el estado de la oferta.
enum OfferStatus {
  published, // Activa, visible
  closed,    // Cerrada, no visible para aplicantes
  inactive,  // Desactivada (si aplica)
  unknown;

  static OfferStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'published':
        return OfferStatus.published;
      case 'closed':
        return OfferStatus.closed;
      case 'inactive':
        return OfferStatus.inactive;
      default:
        return OfferStatus.unknown;
    }
  }
}

/// Modelo para el pago (información de la oferta).
class Payment {
  const Payment({
    required this.amount,
    required this.currency,
    this.period,
  });

  final double amount;
  final String currency;
  final String? period;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'DOP',
      period: json['period'],
    );
  }
}

/// Modelo para preguntas adicionales (simplificado).
class Question {
  const Question({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
  });

  final String id;
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}