import 'package:ocupa2/core/network/json_parsing.dart';
import 'package:ocupa2/features/job_search/data/models/offer_question.dart';

/// Oferta de empleo (GET /offers, GET /offers/{id}).
///
/// IMPORTANTE: el Swagger no mostraba un ejemplo completo del JSON de
/// respuesta al momento de construir este modelo (solo el cuerpo que se
/// envía al publicar en POST /offers). Los nombres de campo de abajo son
/// la mejor suposición basada en ese cuerpo de creación. Antes de dar por
/// buena esta pantalla, hacer un GET /offers real (Postman o "Try it out"
/// en Swagger) y ajustar los nombres si no calzan — está todo centralizado
/// en este único factory, así que el arreglo es rápido.
///
/// La identidad de quien publica permanece oculta para quien aplica, por
/// eso este modelo no incluye datos del publicante.
class Offer {
  const Offer({
    required this.id,
    required this.jobTypeKey,
    this.jobTypeName,
    required this.contractType,
    required this.description,
    required this.address,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.paymentAmount,
    this.paymentCurrency,
    this.deadline,
    this.questions = const <OfferQuestion>[],
  });

  final String id;
  final String jobTypeKey;
  final String? jobTypeName;
  final String contractType;
  final String description;
  final String address;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final num? paymentAmount;
  final String? paymentCurrency;
  final DateTime? deadline;
  final List<OfferQuestion> questions;

  /// Etiqueta lista para mostrar en pantalla (usa el nombre si vino del
  /// API, o el key crudo como respaldo).
  String get displayJobType => jobTypeName?.trim().isNotEmpty == true
      ? jobTypeName!.trim()
      : jobTypeKey;

  factory Offer.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una oferta',
    );

    final Object? location = map['location'];
    final Map<String, dynamic>? locationMap =
        location is Map ? location.map((Object? k, Object? v) {
              return MapEntry<String, dynamic>(k.toString(), v);
            }) : null;

    final Object? payment = map['payment'];
    final Map<String, dynamic>? paymentMap =
        payment is Map ? payment.map((Object? k, Object? v) {
              return MapEntry<String, dynamic>(k.toString(), v);
            }) : null;

    final List<dynamic>? rawQuestions = map['questions'] as List<dynamic>?;

    return Offer(
      id: requireString(map, 'id', context: 'Una oferta'),
      jobTypeKey: requireString(map, 'jobTypeKey', context: 'Una oferta'),
      jobTypeName: (map['jobTypeName'] as String?)?.trim(),
      contractType:
          requireString(map, 'contractType', context: 'Una oferta'),
      description:
          requireString(map, 'description', context: 'Una oferta'),
      address: requireString(map, 'address', context: 'Una oferta'),
      photoUrl: (map['photo'] as String?) ?? (map['photoUrl'] as String?),
      latitude: _asDouble(locationMap?['lat']),
      longitude: _asDouble(locationMap?['lng']),
      paymentAmount: paymentMap?['amount'] as num?,
      paymentCurrency: paymentMap?['currency'] as String?,
      deadline: _asDate(map['deadline']),
      questions:
          rawQuestions?.map(OfferQuestion.fromJson).toList() ??
              const <OfferQuestion>[],
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static DateTime? _asDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
