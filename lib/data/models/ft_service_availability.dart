class FtServiceAvailability {
  const FtServiceAvailability({
    required this.total,
    required this.booked,
    required this.available,
  });

  final int total;
  final int booked;
  final int available;

  factory FtServiceAvailability.fromSupabase(Object? value) {
    final row = value is Map<String, dynamic>
        ? value
        : value is Map
            ? Map<String, dynamic>.from(value)
            : const <String, dynamic>{};
    int read(String key) {
      final value = row[key];
      return value is int ? value : int.tryParse('$value') ?? 0;
    }

    return FtServiceAvailability(
      total: read('total'),
      booked: read('booked'),
      available: read('available'),
    );
  }
}
