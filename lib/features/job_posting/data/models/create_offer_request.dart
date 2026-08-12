import 'offer_location.dart';
import 'offer_payment.dart';
import 'offer_question.dart';

/// Body exacto confirmado en el swagger para POST /offers.
class CreateOfferRequest {
  final String jobTypeKey;
  final String contractType;
  final String description;
  final String address;
  final String? photo;
  final String? paymentId;
  final OfferLocation location;
  final OfferPayment payment;
  final DateTime deadline;
  final Map<String, dynamic> customAnswers;
  final List<OfferQuestion> questions;

  const CreateOfferRequest({
    required this.jobTypeKey,
    required this.contractType,
    required this.description,
    required this.address,
    this.photo,
    this.paymentId,
    required this.location,
    required this.payment,
    required this.deadline,
    this.customAnswers = const {},
    this.questions = const [],
  });

  Map<String, dynamic> toJson() => {
        'jobTypeKey': jobTypeKey,
        'contractType': contractType,
        'description': description,
        'address': address,
        if (photo != null) 'photo': photo,
        if (paymentId != null) 'paymentId': paymentId,
        'location': location.toJson(),
        'payment': payment.toJson(),
        'deadline': _formatDate(deadline),
        'customAnswers': customAnswers,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');

    return '$y-$m-$day';
  }
}