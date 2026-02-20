T grabRequiredValue<T>(Map<String, dynamic> json, String key) {
  return _grabValue(json, key, required: true)!;
}

T? grabOptionalValue<T>(Map<String, dynamic> json, String key) {
  return _grabValue(json, key, required: false);
}

T? _grabValue<T>(
  Map<String, dynamic> json,
  String key, {
  required bool required,
}) {
  if (required && !json.containsKey(key)) {
    throw Exception('$key missing');
  }

  final value = json[key];

  if (value == null) {
    if (required) {
      throw Exception('$key is null');
    }
    return null;
  }

  if (value is! T) {
    throw Exception(
      'Expected type ${T.runtimeType} for `$key` but got ${value.runtimeType}',
    );
  }
  return value;
}
