class OfferLocation {
  final double lat;
  final double lng;

  const OfferLocation({required this.lat, required this.lng});

  factory OfferLocation.fromJson(Map<String, dynamic> json) {
    return OfferLocation(
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };
}
