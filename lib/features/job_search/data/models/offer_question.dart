import 'package:ocupa2/core/network/json_parsing.dart';

/// Pregunta adicional que quien publicó la oferta definió para sus
/// aplicantes. El "id" solo existe cuando la pregunta viene en una oferta
/// ya publicada (el API la genera); al crear la oferta no se manda.
class OfferQuestion {
  const OfferQuestion({
    this.id,
    required this.label,
    required this.type,
    required this.required,
    this.options = const <String>[],
  });

  final String? id;
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  factory OfferQuestion.fromJson(Object? json) {
    final Map<String, dynamic> map = requireJsonObject(
      json,
      context: 'Una pregunta de la oferta',
    );

    return OfferQuestion(
      id: (map['id'] as String?)?.trim(),
      label: requireString(map, 'label', context: 'Una pregunta de la oferta'),
      type: requireString(map, 'type', context: 'Una pregunta de la oferta'),
      required: map['required'] == true,
      options:
          (map['options'] as List<dynamic>?)
              ?.map((Object? option) => option.toString())
              .toList() ??
          const <String>[],
    );
  }
}
