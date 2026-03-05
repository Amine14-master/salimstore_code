void main() {
  dynamic productIds = {"-Oxyz": "productRefKey"};

  List<String> parseStringList(dynamic source) {
    if (source == null) return [];
    if (source is Iterable) {
      return source
          .map((e) => e?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (source is Map) {
      return source.values
          .map((e) => e?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  print(parseStringList(productIds));
}
