class ChangePasswordRequest {
  const ChangePasswordRequest({required this.password});

  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'password': password};
  }
}
