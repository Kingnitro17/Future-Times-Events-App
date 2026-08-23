class ZimbabweLocation {
  const ZimbabweLocation({
    required this.displayName,
    required this.normalizedName,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.isMajor = false,
  });

  final String displayName;
  final String normalizedName;
  final String province;
  final double latitude;
  final double longitude;
  final bool isMajor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZimbabweLocation &&
          runtimeType == other.runtimeType &&
          normalizedName == other.normalizedName;

  @override
  int get hashCode => normalizedName.hashCode;
}
