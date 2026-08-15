import 'package:ocupa2/core/network/json_parsing.dart';

class Experience {
  const Experience({
    required this.id,
    required this.title,
    required this.description,
    this.jobTypeKey,
    this.certificateImage,
    this.contractType,
    this.duration,
  });

  final String id;
  final String title;
  final String description;
  final String? jobTypeKey;
  final String? certificateImage;
  final String? contractType;
  final String? duration;

  String get metaLabel {
    final String contract = _contractLabel(contractType);
    final String time = duration?.trim() ?? '';
    if (contract.isNotEmpty && time.isNotEmpty) {
      return '$contract · $time';
    }
    if (contract.isNotEmpty) {
      return contract;
    }
    return time;
  }

  factory Experience.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una experiencia',
    );

    final String? rawTitle = (map['title'] as String?) ??
        (map['name'] as String?) ??
        (map['jobTitle'] as String?) ??
        (map['position'] as String?);

    final String? rawDescription = (map['description'] as String?) ??
        (map['summary'] as String?) ??
        (map['details'] as String?) ??
        '';

    final String? imageUrl = (map['certificateImage'] as String?) ??
        (map['certificate'] as String?) ??
        (map['certificateUrl'] as String?) ??
        (map['image'] as String?) ??
        (map['imageUrl'] as String?) ??
        (map['photo'] as String?) ??
        (map['photoUrl'] as String?);

    final String titleValue = rawTitle?.trim() ?? '';
    final String? imageValue = imageUrl?.trim();
    final String safeTitle = titleValue.isNotEmpty ? titleValue : 'Experiencia profesional';
    final String? safeImage = imageValue != null && imageValue.isNotEmpty ? imageValue : null;

    final Object? rawYears = map['years'] ?? map['yearsOfExperience'];
    final String? yearsLabel = rawYears is num
        ? (rawYears == 1 ? '1 año' : '${rawYears.round()} años')
        : null;

    return Experience(
      id: (map['id'] as String?)?.trim() ?? 'experience-${DateTime.now().microsecondsSinceEpoch}',
      title: safeTitle,
      description: rawDescription?.trim() ?? '',
      jobTypeKey: (map['jobTypeKey'] as String?)?.trim(),
      certificateImage: safeImage,
      contractType: (map['contractType'] as String?)?.trim(),
      duration: (map['duration'] as String?)?.trim() ?? yearsLabel,
    );
  }
}

String _contractLabel(String? value) {
  return switch ((value ?? '').toLowerCase().trim()) {
    'fixed' || 'fijo' => 'Fijo',
    'hourly' || 'por_horas' || 'por-horas' => 'Por horas',
    'temporary' || 'temporal' => 'Temporal',
    '' => '',
    _ => value!.trim(),
  };
}
