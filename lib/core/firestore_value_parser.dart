DateTime parseDateTimeValue(Object? value, {required String fieldName}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }

  // Firebase's Timestamp exposes toDate(), but the domain layer deliberately
  // avoids importing Firebase packages so it remains testable without config.
  if (value != null) {
    try {
      final dynamic timestamp = value;
      final converted = timestamp.toDate();
      if (converted is DateTime) return converted;
    } on NoSuchMethodError {
      // Not a Firebase Timestamp; report the common format error below.
    } on TypeError {
      // The timestamp implementation returned an unexpected type.
    }
  }

  throw FormatException('Missing or invalid "$fieldName".');
}
