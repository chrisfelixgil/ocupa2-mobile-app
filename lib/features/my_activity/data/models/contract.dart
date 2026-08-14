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
      'accepted' || 'approved' || 'active' || 'confirmed' || 'in_progress' || 'in-progress' || 'aceptado' => 'active',
      'pending' || 'waiting' || 'review' || 'awaiting' || 'pendiente' => 'pending',
      'rejected' || 'declined' || 'denied' || 'rechazado' => 'rejected',
      'cancelled' || 'canceled' || 'cancelado' => 'cancelled',
      _ => status,
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

    final Object? rawSalary = map['salary'];
    final num? salaryVal = rawSalary is num ? rawSalary : num.tryParse(asText(rawSalary) ?? '');

    final DateTime? start = DateTime.tryParse(asText(map['startDate']) ?? '');
    final DateTime? created = DateTime.tryParse(asText(map['createdAt']) ?? '');
    final DateTime? accepted = DateTime.tryParse(asText(map['acceptedAt']) ?? '');
    final DateTime? cancelled = DateTime.tryParse(asText(map['cancelledAt']) ?? '');

    final List<dynamic>? rawComments = map['comments'] is List ? map['comments'] as List<dynamic> : null;
    final List<dynamic>? rawPhotos = map['photos'] is List ? map['photos'] as List<dynamic> : null;

    final String resolvedStatus = normalizeStatus(
      asText(map['status']) ??
          asText(map['contractStatus']) ??
          asText(map['state']) ??
          'pending',
    );

    return Contract(
      id: asText(map['id']) ?? 'unknown-contract',
      myRole: normalizeRole(
        asText(map['myRole']) ??
            asText(map['role']) ??
            asText(map['userRole']) ??
            asText(map['contractRole']) ??
            'contratante',
      ),
      status: resolvedStatus,
      offerId: asText(map['offerId']),
      jobTypeName: asText(map['jobTypeName']) ?? asText(map['title']),
      contratante: parseParty(map['contratante'] ?? map['employer'] ?? map['contractor']),
      contratado: parseParty(map['contratado'] ?? map['employee'] ?? map['worker'] ?? map['candidate']),
      salary: salaryVal,
      currency: asText(map['currency']) ?? 'DOP',
      startDate: start,
      duration: asText(map['duration']),
      createdAt: created,
      acceptedAt: accepted,
      cancelJustification: asText(map['cancelJustification']) ?? asText(map['justification']),
      cancelledBy: parseParty(map['cancelledBy'] ?? map['canceledBy']),
      cancelledAt: cancelled,
      comments: rawComments?.map(ContractComment.fromJson).whereType<ContractComment>().toList() ?? const <ContractComment>[],
      photos: rawPhotos?.map(ContractPhoto.fromJson).whereType<ContractPhoto>().toList() ?? const <ContractPhoto>[],
    );
  }
}