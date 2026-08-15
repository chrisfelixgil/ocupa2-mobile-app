class EducationalVideo {
  final String id;
  final String youtubeId;
  final String url;
  final String title;
  final String description;
  final String thumbnail;
  final int order;

  const EducationalVideo({
    required this.id,
    required this.youtubeId,
    required this.url,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.order,
  });

  factory EducationalVideo.fromJson(Map<String, dynamic> json) {
    return EducationalVideo(
      id: json['id']?.toString() ?? '',
      youtubeId: json['youtubeId']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse(json['order']?.toString() ?? '') ?? 0,
    );
  }
}
