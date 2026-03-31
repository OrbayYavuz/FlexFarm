class CropPriceData {
  final String cropId;
  final double minPricePerKg;
  final double maxPricePerKg;
  final String marketName;
  final DateTime lastUpdated;

  CropPriceData({
    required this.cropId,
    required this.minPricePerKg,
    required this.maxPricePerKg,
    required this.marketName,
    required this.lastUpdated,
  });

  factory CropPriceData.fromJson(Map<String, dynamic> json) {
    return CropPriceData(
      cropId: json['crop_id'] ?? '',
      minPricePerKg: (json['price_per_kg_min'] ?? 0).toDouble(),
      maxPricePerKg: (json['price_per_kg_max'] ?? 0).toDouble(),
      marketName: json['market_name'] ?? 'Bilinmiyor',
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : DateTime.now(),
    );
  }

  double get averagePricePerKg => (minPricePerKg + maxPricePerKg) / 2;
}
