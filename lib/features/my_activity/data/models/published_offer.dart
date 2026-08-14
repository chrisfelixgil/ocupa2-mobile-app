/// Oferta publicada por el usuario autenticado (GET /me/offers).
class PublishedOffer {
  const PublishedOffer({
    required this.id,
    required this.jobTypeName,
    required this.address,
    this.photoUrl,
    this.status = 'published', // Cambia el valor por defecto a 'published'
  });

  final String id;
  final String jobTypeName;
  final String address;
  final String? photoUrl;
  final String status;

  // Ahora considera 'published' como activo
  bool get isActive => status == 'published';

  factory PublishedOffer.fromJson(Object? json) {
    final Map<String, dynamic> map = json is Map
        ? json.map((Object? key, Object? value) {
            return MapEntry<String, dynamic>(key.toString(), value);
          })
        : const <String, dynamic>{};

    return PublishedOffer(
      id: (map['id'] ?? map['_id'])?.toString() ?? '',
      jobTypeName: (map['jobTypeName'] as String?)?.trim().isNotEmpty == true
          ? (map['jobTypeName'] as String).trim()
          : (map['jobTypeKey'] as String?)?.trim() ?? 'Oferta',
      address: (map['address'] as String?)?.trim() ?? '',
      photoUrl: (map['photo'] as String?) ?? (map['photoUrl'] as String?),
      status: (map['status'] as String?)?.trim() ?? 'published', // Cambia el default
    );
  }
}