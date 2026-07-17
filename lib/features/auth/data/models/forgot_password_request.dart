class ForgotPasswordRequest {
  const ForgotPasswordRequest({
    required this.email,
    required this.referralMatricula,
  });

  final String email;
  final String referralMatricula;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email.trim(),
      'referralMatricula': referralMatricula.trim(),
    };
  }
}
