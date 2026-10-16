DateTime? parseDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;

    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
    if (!hasTimezone) return parsed;

    final wib = parsed.toUtc().add(const Duration(hours: 7));
    return DateTime(
      wib.year,
      wib.month,
      wib.day,
      wib.hour,
      wib.minute,
      wib.second,
      wib.millisecond,
      wib.microsecond,
    );
  }
  return null;
}
