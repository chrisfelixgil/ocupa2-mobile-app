import 'offer_location.dart';
import 'offer_payment.dart';
import 'offer_question.dart';
import 'offer_status.dart';

class Offer {
  final String id;
  final String jobTypeKey;
  final String jobTypeName;
  final String contractType;
  final String description;
  final String address;
  final String? photo;
  final String? paymentId;
  final OfferLocation location;
  final OfferPayment payment;
  final DateTime? deadline;
  final OfferStatus status;
  final List<dynamic> customAnswers;
  final List<OfferQuestion> questions;
  final DateTime? createdAt;

  const Offer({
    required this.id,
    required this.jobTypeKey,
    required this.jobTypeName,
    required this.contractType,
    required this.description,
    required this.address,
    this.photo,
    this.paymentId,
    required this.location,
    required this.payment,
    this.deadline,
    this.status = OfferStatus.active,
    this.customAnswers = const [],
    this.questions = const [],
    this.createdAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final locationJson = json['location'];
    final paymentJson = json['payment'];
    final questionsJson = json['questions'];
    final customAnswersJson = json['customAnswers'];

    return Offer(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',

      jobTypeKey: json['jobTypeKey']?.toString() ?? '',

      // Viene de la respuesta de la API
      jobTypeName: json['jobTypeName']?.toString() ?? '',

      contractType: json['contractType']?.toString() ?? '',

      description: json['description']?.toString() ?? '',

      address: json['address']?.toString() ?? '',

      photo: json['photo']?.toString(),

      paymentId: json['paymentId']?.toString(),

      location: locationJson is Map
          ? OfferLocation.fromJson(
              Map<String, dynamic>.from(locationJson),
            )
          : const OfferLocation(
              lat: 0,
              lng: 0,
            ),

      payment: paymentJson is Map
          ? OfferPayment.fromJson(
              Map<String, dynamic>.from(paymentJson),
            )
          : const OfferPayment(
              amount: 0,
              currency: 'DOP',
            ),

      deadline: json['deadline'] != null
          ? DateTime.tryParse(
              json['deadline'].toString(),
            )
          : null,

      status: offerStatusFromString(
        json['status']?.toString(),
      ),

      customAnswers: customAnswersJson is List
          ? List<dynamic>.from(customAnswersJson)
          : const [],

      questions: questionsJson is List
          ? questionsJson
              .whereType<Map>()
              .map(
                (q) => OfferQuestion.fromJson(
                  Map<String, dynamic>.from(q),
                ),
              )
              .toList()
          : const [],

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,
    );
  }
}