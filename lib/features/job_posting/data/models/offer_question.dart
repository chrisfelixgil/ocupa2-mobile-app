/// Tipos de pregunta soportados por el backend.
class OfferQuestionType {
  static const text = 'text';
  static const date = 'date';
  static const select = 'select';
  static const check = 'check';
}

class OfferQuestion {
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  const OfferQuestion({
    required this.label,
    required this.type,
    required this.required,
    this.options = const [],
  });

  factory OfferQuestion.fromJson(Map<String, dynamic> json) {
    return OfferQuestion(
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? OfferQuestionType.text,
      required: json['required'] as bool? ?? false,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type,
        'required': required,
        'options': options,
      };
}