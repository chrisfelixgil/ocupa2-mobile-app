
class News {
  final String title;
  final String image;
  final String summary;
  final DateTime? date;
  final String url;
  final String source;

  const News({
    required this.title,
    required this.image,
    required this.summary,
    required this.date,
    required this.url,
    required this.source,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}