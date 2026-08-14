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

  static String normalizeStatus(String? rawStatus) {
    final String status = rawStatus?.trim().toLowerCase() ?? '';
    return switch (status) {
      'accepted' || 'approved' || 'active' || 'confirmed' || 'in_progress' || 'in-progress' => 'active',
      'pending' || 'waiting' || 'review' || 'awaiting' => 'pending',
      'rejected' || 'declined' || 'denied' => 'rejected',
      'cancelled' || 'canceled' || 'cancelado' => 'cancelled',
      _ => status,
    };
  }

  static String normalizeRole(String? rawRole) {
    final String role = rawRole?.trim().toLowerCase() ?? '';
    return switch (role) {
      'contratante' || 'employer' || 'owner' || 'hiring' || 'contractor' => 'contratante',
      'contratado' || 'employee' || 'candidate' || 'worker' || 'contractee' => 'contratado',
      _ => role,
    };
  }

  bool get isContratante => normalizeRole(myRole) == 'contratante';
  bool get isContratado => normalizeRole(myRole) == 'contratado';

  bool get isPending => normalizeStatus(status) == 'pending';
  bool get isActive => normalizeStatus(status) == 'active';
  bool get isRejected => normalizeStatus(status) == 'rejected';
  bool get isCancelled => normalizeStatus(status) == 'cancelled';

  bool get hasTerms => salary != null || startDate != null || (duration != null && duration!.trim().isNotEmpty);

  ContractParty? get otherParty => isContratante ? contratado : contratante;

  String get displayTitle => jobTypeName?.trim().isNotEmpty == true
      ? jobTypeName!.trim()
      : 'Contrato de trabajo';

  String get displayStatusLabel {
    return switch (normalizeStatus(status)) {
      'pending' => 'Pendiente',
      'active' => 'Activo',
      'rejected' => 'Rechazado',
      'cancelled' => 'Cancelado',
      _ => status,
    };
  }

  factory Contract.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Un contrato',
    );

    ContractParty? parseParty(Object? raw) {
      if (raw == null) return null;
      try {
        return ContractParty.fromJson(raw);
      } catch (_) {
        return null;
      }
    }

    final Object? rawSalary = map['salary'];
    final num? salaryVal = rawSalary is num ? rawSalary : null;

    final Object? rawStartDate = map['startDate'];
    final DateTime? start = rawStartDate is String
        ? DateTime.tryParse(rawStartDate.trim())
        : null;

    final Object? rawCreatedAt = map['createdAt'];
    final DateTime? created = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt.trim())
        : null;

    final Object? rawAcceptedAt = map['acceptedAt'];
    final DateTime? accepted = rawAcceptedAt is String
        ? DateTime.tryParse(rawAcceptedAt.trim())
        : null;

    final Object? rawCancelledAt = map['cancelledAt'];
    final DateTime? cancelled = rawCancelledAt is String
        ? DateTime.tryParse(rawCancelledAt.trim())
        : null;

    final List<dynamic>? rawComments = map['comments'] as List<dynamic>?;
    final List<dynamic>? rawPhotos = map['photos'] as List<dynamic>?;

    final String contractStatus = normalizeStatus(
      (map['status'] as String?) ?? (map['contractStatus'] as String?) ?? (map['state'] as String?),
    );

    return Contract(
      id: requireString(map, 'id', context: 'Un contrato'),
      myRole: normalizeRole(
            (map['myRole'] as String?) ??
                (map['role'] as String?) ??
                (map['userRole'] as String?) ??
                (map['contractRole'] as String?) ??
                'contratante',
          ),
      status: contractStatus.isEmpty ? 'pending' : contractStatus,
      offerId: (map['offerId'] as String?)?.trim(),
      jobTypeName: (map['jobTypeName'] as String?)?.trim() ?? (map['title'] as String?)?.trim(),
      contratante: parseParty(map['contratante'] ?? map['employer'] ?? map['contractor']),
      contratado: parseParty(map['contratado'] ?? map['employee'] ?? map['worker'] ?? map['candidate']),
      salary: salaryVal,
      currency: (map['currency'] as String?)?.trim() ?? 'DOP',
      startDate: start,
      duration: (map['duration'] as String?)?.trim(),
      createdAt: created,
      acceptedAt: accepted,
      cancelJustification: (map['cancelJustification'] as String?)?.trim() ?? (map['justification'] as String?)?.trim(),
      cancelledBy: parseParty(map['cancelledBy'] ?? map['canceledBy']),
      cancelledAt: cancelled,
      comments: rawComments?.map(ContractComment.fromJson).toList() ?? const <ContractComment>[],
      photos: rawPhotos?.map(ContractPhoto.fromJson).toList() ?? const <ContractPhoto>[],
    );
  }
}
