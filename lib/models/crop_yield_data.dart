enum YieldModifierType {
  irrigation,
  fertilizer,
  soilQuality,
  weatherRisk,
  custom,
}

class YieldModifier {
  final String id;
  final String name;
  final YieldModifierType type;
  final double multiplier; // 1.0 = etki yok, 1.1 = %10 artış
  final String? description;

  const YieldModifier({
    required this.id,
    required this.name,
    required this.type,
    required this.multiplier,
    this.description,
  });
}

class CropData {
  final String id;
  final String name;
  final String scientificName;
  final double baseYieldPerDecare; // KG per 1000m2
  final int averageGrowthDays;
  final String category;

  const CropData({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.baseYieldPerDecare,
    required this.averageGrowthDays,
    required this.category,
  });
}

class YieldCalculationResult {
  final CropData crop;
  final double areaInDecares;
  final double baseExpectedYieldKg;
  final double finalExpectedYieldKg;
  final List<YieldModifier> appliedModifiers;

  YieldCalculationResult({
    required this.crop,
    required this.areaInDecares,
    required this.baseExpectedYieldKg,
    required this.finalExpectedYieldKg,
    required this.appliedModifiers,
  });

  double get finalExpectedYieldTonnes => finalExpectedYieldKg / 1000.0;

  String getFormattedEstimatedYield() {
    if (finalExpectedYieldTonnes >= 1) {
      return '${finalExpectedYieldTonnes.toStringAsFixed(1)} Ton';
    }
    return '${finalExpectedYieldKg.toStringAsFixed(0)} kg';
  }
}
