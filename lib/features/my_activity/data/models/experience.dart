import 'package:ocupa2/core/network/json_parsing.dart';

class Experience {
  const Experience({
    required this.id,
    required this.title,
    required this.description,
    this.jobTypeKey,
    this.certificateImage,
  });

  final String id;
  final String title;
  final String description;
  final String? jobTypeKey;
  final String? certificateImage;

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

    return Experience(
      id: (map['id'] as String?)?.trim() ?? 'experience-${DateTime.now().microsecondsSinceEpoch}',
      title: safeTitle,
      description: rawDescription?.trim() ?? '',
      jobTypeKey: (map['jobTypeKey'] as String?)?.trim(),
      certificateImage: safeImage,
    );
  }
}
