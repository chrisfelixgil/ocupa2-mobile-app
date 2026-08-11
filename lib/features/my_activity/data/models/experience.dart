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

    return Experience(
      id: requireString(map, 'id', context: 'Una experiencia'),
      title: requireString(map, 'title', context: 'Una experiencia'),
      description: requireString(
        map,
        'description',
        context: 'Una experiencia',
      ),
      jobTypeKey: (map['jobTypeKey'] as String?)?.trim(),
      certificateImage: (map['certificateImage'] as String?)?.trim(),
    );
  }
}
