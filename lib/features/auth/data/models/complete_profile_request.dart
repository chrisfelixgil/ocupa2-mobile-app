class CompleteProfileRequest {
  const CompleteProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.cedula,
    required this.gender,
    required this.birthDate,
  });

  final String firstName;
  final String lastName;
  final String cedula;
  final String gender;
  final DateTime birthDate;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'cedula': cedula.replaceAll(RegExp(r'[\s-]'), ''),
      'gender': gender,
      'birthDate': _formatDate(birthDate),
    };
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
