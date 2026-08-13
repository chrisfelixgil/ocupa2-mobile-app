class ApplyAnswer {
  const ApplyAnswer({required this.questionId, required this.value});

  final String questionId;
  final String value;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'questionId': questionId, 'value': value};
  }
}

/// Cuerpo de POST /offers/{id}/apply.
class ApplyRequest {
  const ApplyRequest({
    required this.comment,
    this.answers = const <ApplyAnswer>[],
  });

  final String comment;
  final List<ApplyAnswer> answers;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'comment': comment,
      'answers': answers.map((ApplyAnswer answer) => answer.toJson()).toList(),
    };
  }
}
