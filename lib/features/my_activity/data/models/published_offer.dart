/// Oferta publicada por el usuario autenticado (GET /me/offers).
class PublishedOffer {
  const PublishedOffer({
    required this.id,
    required this.jobTypeName,
    required this.address,
    this.photoUrl,
    this.status = 'published',
    this.description,
    this.contractType,
    this.paymentAmount,
    this.paymentCurrency,
    this.applicantsCount = 0,
    this.createdAt,
  });

  final String id;
  final String jobTypeName;
  final String address;
  final String? photoUrl;
  final String status;
  final String? description;
  final String? contractType;
  final num? paymentAmount;
  final String? paymentCurrency;
  final int applicantsCount;
  final DateTime? createdAt;

  bool get isActive {
    final String normalized = status.toLowerCase().trim();
    return normalized == 'published' || normalized == 'active';
  }

  String get displayTitle {
    final String text = description?.trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
    return jobTypeName;
  }

  String get displayStatusLabel => isActive ? 'Activa' : 'Finalizada';

  String get metaLabel {
    final String type = jobTypeName.trim();
    final String contract = _contractLabel(contractType);
    if (type.isEmpty) {
      return contract;
    }
    if (contract.isEmpty) {
      return type;
    }
    return '$type · $contract';
  }

  String get paymentLabel {
    if (paymentAmount == null) {
      return 'A convenir';
    }

    final String amount = _group(paymentAmount!.round());
    final String currency = (paymentCurrency ?? 'DOP').toUpperCase();
    if (currency == 'USD' || currency == 'US\$') {
      return 'US\$$amount';
    }
    return 'RD\$$amount';
  }

  String get candidatesLabel {
    if (applicantsCount == 1) {
      return '1 candidato';
    }
    return '$applicantsCount candidatos';
  }

  String get publishedLabel {
    if (createdAt == null) {
      return 'Publicado';
    }

    final DateTime local = createdAt!.toLocal();
    final Duration diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) {
      return 'Publicado: Ahora';
    }
    if (diff.inHours < 1) {
      return 'Publicado: Hace ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Publicado: Hace ${diff.inHours} h';
    }
    if (diff.inDays == 1) {
      return 'Publicado: Hace 1 día';
    }
    if (diff.inDays < 7) {
      return 'Publicado: Hace ${diff.inDays} días';
    }

    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return 'Publicado: ${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
  }

  factory PublishedOffer.fromJson(Object? json) {
    final Map<String, dynamic> map = json is Map
        ? json.map((Object? key, Object? value) {
            return MapEntry<String, dynamic>(key.toString(), value);
          })
        : const <String, dynamic>{};

    final Map<String, dynamic>? paymentMap = _asMap(map['payment']);

    return PublishedOffer(
      id: (map['id'] ?? map['_id'])?.toString() ?? '',
      jobTypeName: (map['jobTypeName'] as String?)?.trim().isNotEmpty == true
          ? (map['jobTypeName'] as String).trim()
          : (map['jobTypeKey'] as String?)?.trim() ?? 'Oferta',
      address: (map['address'] as String?)?.trim() ?? '',
      photoUrl: (map['photo'] as String?) ?? (map['photoUrl'] as String?),
      status: (map['status'] as String?)?.trim() ?? 'published',
      description: (map['description'] as String?)?.trim(),
      contractType: (map['contractType'] as String?)?.trim(),
      paymentAmount:
          (paymentMap?['amount'] as num?) ??
          (map['amount'] as num?) ??
          (map['salary'] as num?),
      paymentCurrency:
          (paymentMap?['currency'] as String?)?.trim() ??
          (map['currency'] as String?)?.trim(),
      applicantsCount: _readApplicantsCount(map),
      createdAt: DateTime.tryParse(
        (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      ),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static int _readApplicantsCount(Map<String, dynamic> map) {
    final Object? raw =
        map['applicantsCount'] ??
        map['applicationsCount'] ??
        map['candidatesCount'];
    if (raw is num) {
      return raw.toInt();
    }

    final Object? applications = map['applications'] ?? map['applicants'];
    if (applications is List) {
      return applications.length;
    }
    return 0;
  }

  static String _contractLabel(String? contractType) {
    switch ((contractType ?? '').toLowerCase()) {
      case 'temporal':
        return 'Temporal';
      case 'fijo':
        return 'Fijo';
      case 'horas':
        return 'Por horas';
      default:
        return contractType?.trim() ?? '';
    }
  }

  static String _group(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }
}
