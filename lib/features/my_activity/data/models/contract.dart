import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_party.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';

class Contract {
  const Contract({
    required this.id,
    required this.myRole,
    required this.status,
    this.offerId,
    this.jobTypeName,
    this.offerDescription,
    this.contratante,
    this.contratado,
    this.salary,
    this.currency,
    this.startDate,
    this.duration,
    this.createdAt,
    this.acceptedAt,
    this.cancelJustification,
    this.cancelledBy,
    this.cancelledAt,
    this.comments = const <ContractComment>[],
    this.photos = const <ContractPhoto>[],
  });

  final String id;
  final String myRole;
  final String status;
  final String? offerId;
  final String? jobTypeName;
  final String? offerDescription;
  final ContractParty? contratante;
  final ContractParty? contratado;
  final num? salary;
  final String? currency;
  final DateTime? startDate;
  final String? duration;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final String? cancelJustification;
  final ContractParty? cancelledBy;
  final DateTime? cancelledAt;
  final List<ContractComment> comments;
  final List<ContractPhoto> photos;

  static String normalizeRole(String? rawRole) {
    final String role = rawRole?.trim().toLowerCase() ?? '';
    return switch (role) {
      'contratante' || 'employer' || 'owner' || 'hiring' || 'contractor' || 'empleador' => 'contratante',
      'contratado' || 'employee' || 'candidate' || 'worker' || 'contractee' || 'empleado' => 'contratado',
      _ => role,
    };
  }

  static String normalizeStatus(String? rawStatus) {
    final String status = rawStatus?.trim().toLowerCase() ?? '';
    return switch (status) {
      'accepted' || 'approved' || 'active' || 'activo' || 'confirmed' || 'in_progress' || 'in-progress' || 'aceptado' || 'vigente' => 'active',
      'pending' || 'waiting' || 'review' || 'awaiting' || 'pendiente' => 'pending',
      'rejected' || 'declined' || 'denied' || 'rechazado' => 'rejected',
      'cancelled' || 'canceled' || 'cancelado' => 'cancelled',
      _ => status,
    };
  }

  bool get isContratante => normalizeRole(myRole) == 'contratante';
  bool get isContratado => normalizeRole(myRole) == 'contratado';

  bool get isRejected => normalizeStatus(status) == 'rejected';
  bool get isCancelled => normalizeStatus(status) == 'cancelled';

  bool get isPending => normalizeStatus(status) == 'pending' && acceptedAt == null && !isRejected && !isCancelled;

  /// El OpenAPI define `active` tras aceptar. Si el GET sigue en pending pero
  /// ya hay `acceptedAt`, el contrato ya está vigente.
  bool get isActive {
    if (isRejected || isCancelled) return false;
    if (normalizeStatus(status) == 'active') return true;
    return acceptedAt != null;
  }

  /// Pendiente o activo: el contrato todavía está en curso.
  bool get isOngoing => isPending || isActive;

  /// Rechazado o cancelado: ya no está vigente.
  bool get isClosed => isRejected || isCancelled;

  Contract copyWith({
    String? status,
    num? salary,
    String? currency,
    DateTime? startDate,
    String? duration,
    DateTime? acceptedAt,
    String? cancelJustification,
    DateTime? cancelledAt,
    List<ContractComment>? comments,
    List<ContractPhoto>? photos,
  }) {
    return Contract(
      id: id,
      myRole: myRole,
      status: status ?? this.status,
      offerId: offerId,
      jobTypeName: jobTypeName,
      offerDescription: offerDescription,
      contratante: contratante,
      contratado: contratado,
      salary: salary ?? this.salary,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      duration: duration ?? this.duration,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      cancelJustification: cancelJustification ?? this.cancelJustification,
      cancelledBy: cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      comments: comments ?? this.comments,
      photos: photos ?? this.photos,
    );
  }

  bool get hasTerms => salary != null || startDate != null || (duration != null && duration!.trim().isNotEmpty);

  ContractParty? get otherParty => isContratante ? contratado : contratante;

  String get displayTitle => jobTypeName?.trim().isNotEmpty == true
      ? jobTypeName!.trim()
      : 'Contrato de trabajo';

  String get displayStatusLabel {
    if (isCancelled) return 'Cancelado';
    if (isRejected) return 'Rechazado';
    if (isActive) return 'Activo';
    if (isPending) return 'Pendiente';
    return status;
  }

  factory Contract.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Un contrato',
    );

    String? asText(Object? value) {
      if (value == null) return null;
      if (value is String) return value.trim();
      if (value is num || value is bool) return value.toString().trim();
      return value.toString().trim();
    }

    ContractParty? parseParty(Object? raw) {
      if (raw == null) return null;
      try {
        return ContractParty.fromJson(raw);
      } catch (_) {
        return null;
      }
    }

    final Object? rawTerms = map['terms'];
    final Map<String, dynamic>? termsMap = rawTerms is Map<String, dynamic>
        ? rawTerms
        : rawTerms is Map
            ? Map<String, dynamic>.from(rawTerms)
            : null;

    final Object? rawSalary =
        map['salary'] ?? termsMap?['salary'] ?? map['amount'] ?? map['monto'] ?? termsMap?['amount'];
    final num? salaryVal = rawSalary is num ? rawSalary : num.tryParse(asText(rawSalary) ?? '');

    final DateTime? start = DateTime.tryParse(
      asText(map['startDate']) ?? asText(termsMap?['startDate']) ?? '',
    );
    final DateTime? created = DateTime.tryParse(asText(map['createdAt']) ?? '');
    DateTime? accepted = DateTime.tryParse(asText(map['acceptedAt']) ?? '');
    if (accepted == null && map['accepted'] == true) {
      accepted = created;
    }
    final DateTime? cancelled = DateTime.tryParse(asText(map['cancelledAt']) ?? '');

    final Object? rawComments = map['comments'] ?? map['messages'];
    final Object? rawPhotos = map['photos'] ?? map['images'];

    final String? cancelJustification =
        asText(map['cancelJustification']) ?? asText(map['justification']);

    String resolvedStatus = normalizeStatus(
      asText(map['status']) ??
          asText(map['contractStatus']) ??
          asText(map['state']),
    );
    if (cancelled != null ||
        (cancelJustification != null && cancelJustification.isNotEmpty)) {
      if (resolvedStatus.isEmpty ||
          resolvedStatus == 'pending' ||
          resolvedStatus == 'active') {
        resolvedStatus = 'cancelled';
      }
    }
    if (resolvedStatus.isEmpty) {
      resolvedStatus = 'pending';
    }

    final Map<String, dynamic>? offerMap = map['offer'] is Map<String, dynamic>
        ? map['offer'] as Map<String, dynamic>
        : map['offer'] is Map
            ? Map<String, dynamic>.from(map['offer'] as Map)
            : null;

    return Contract(
      id: asText(map['id']) ?? asText(map['_id']) ?? 'unknown-contract',
      myRole: normalizeRole(
        asText(map['myRole']) ??
            asText(map['role']) ??
            asText(map['userRole']) ??
            asText(map['contractRole']) ??
            'contratante',
      ),
      status: resolvedStatus,
      offerId: asText(map['offerId']) ?? asText(offerMap?['id']),
      jobTypeName: asText(map['jobTypeName']) ??
          asText(map['title']) ??
          asText(offerMap?['jobTypeName']) ??
          asText(offerMap?['title']),
      offerDescription: asText(map['description']) ??
          asText(map['offerDescription']) ??
          asText(offerMap?['description']),
      contratante: parseParty(map['contratante'] ?? map['employer'] ?? map['contractor']),
      contratado: parseParty(map['contratado'] ?? map['employee'] ?? map['worker'] ?? map['candidate']),
      salary: salaryVal,
      currency: asText(map['currency']) ?? asText(termsMap?['currency']) ?? 'DOP',
      startDate: start,
      duration: asText(map['duration']) ?? asText(termsMap?['duration']),
      createdAt: created,
      acceptedAt: accepted,
      cancelJustification: cancelJustification,
      cancelledBy: parseParty(map['cancelledBy'] ?? map['canceledBy']),
      cancelledAt: cancelled,
      comments: _parseItemList(rawComments, ContractComment.fromJson),
      photos: _parseItemList(rawPhotos, ContractPhoto.fromJson),
    );
  }

  static List<T> _parseItemList<T>(
    Object? raw,
    T Function(Object? json) parse,
  ) {
    if (raw is! List) {
      return <T>[];
    }

    final List<T> items = <T>[];
    for (final Object? item in raw) {
      try {
        items.add(parse(item));
      } catch (_) {
        // Si un comentario o foto viene mal formado, se omite y no se pierde el contrato.
      }
    }
    return items;
  }
}