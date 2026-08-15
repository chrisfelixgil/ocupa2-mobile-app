/// Tipos de pregunta soportados por el backend.
class OfferQuestionType {
  static const text = 'text';
  static const date = 'date';
  static const select = 'select';
  static const check = 'check';
  static const boolean = 'boolean';
}

class OfferQuestion {
  final String? id;
  final String label;
  final String type;
  final bool required;
  final List<String> options;

  const OfferQuestion({
    this.id,
    required this.label,
    required this.type,
    required this.required,
    this.options = const [],
  });

  factory OfferQuestion.fromJson(Map<String, dynamic> json) {
    final String rawType = (json['type'] as String? ?? OfferQuestionType.text)
        .trim()
        .toLowerCase();

    return OfferQuestion(
      id: (json['id'] as String?)?.trim(),
      label: json['label'] as String? ?? '',
      type: rawType == 'boolean'
          ? OfferQuestionType.check
          : rawType == 'date' || rawType == 'check' || rawType == 'select' || rawType == 'text'
              ? rawType
              : OfferQuestionType.text,
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