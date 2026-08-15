/// Fechas de customFields: el API usa date-only ISO; la UI usa un formato local.
class CustomFieldDate {
  const CustomFieldDate._();

  /// Valor enviado en customAnswers: `yyyy-MM-dd`.
  static String toApi(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Texto visible en el formulario. No se envía al API.
  static String toDisplay(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
