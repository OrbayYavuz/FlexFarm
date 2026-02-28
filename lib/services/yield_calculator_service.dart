import '../models/crop_yield_data.dart';

class YieldCalculatorService {
  
  static YieldCalculationResult calculateYield({
    required CropData crop,
    required double areaInSqMeters,
    List<YieldModifier> modifiers = const [],
  }) {
    // 1 dekar = 1000 metrekaredir
    double areaInDecares = areaInSqMeters / 1000.0;

    // Temel Kaba Hesaplama
    double baseYieldKg = areaInDecares * crop.baseYieldPerDecare;

    // Çarpanların (Modifier) Uygulanması
    double finalYieldKg = baseYieldKg;

    for (var modifier in modifiers) {
      finalYieldKg = finalYieldKg * modifier.multiplier;
    }

    return YieldCalculationResult(
      crop: crop,
      areaInDecares: areaInDecares,
      baseExpectedYieldKg: baseYieldKg,
      finalExpectedYieldKg: finalYieldKg,
      appliedModifiers: modifiers,
    );
  }

  static YieldCalculationResult calculateYieldByDecare({
    required CropData crop,
    required double areaInDecares,
    List<YieldModifier> modifiers = const [],
  }) {
    return calculateYield(
      crop: crop,
      areaInSqMeters: areaInDecares * 1000,
      modifiers: modifiers,
    );
  }

  static String generatePromptForAI(YieldCalculationResult result) {
    String prompt = "Şu özelliklerde bir ekim planım var:\n";
    prompt += "Mahsul: ${result.crop.name} (${result.crop.scientificName})\n";
    prompt += "Ekim Alanı: ${result.areaInDecares.toStringAsFixed(2)} Dekar\n";
    prompt += "Tahmini Büyüme Süresi: ${result.crop.averageGrowthDays} gün\n";
    prompt += "Hesaplanmış Beklenen Verim: ${result.finalExpectedYieldKg.toStringAsFixed(0)} kg\n";
    
    if (result.appliedModifiers.isNotEmpty) {
      prompt += "Şu özel koşullar mevcut:\n";
      for (var mod in result.appliedModifiers) {
        prompt += "- ${mod.name} (Etki: ${(mod.multiplier * 100).toStringAsFixed(0)}%)\n";
      }
    }

    prompt += "\nLütfen bu hesaplamaya bakarak bana bir ziraat uzmanı gibi tavsiyelerde bulun. Verimi artırmak için bu mahsule özel püf noktalar nelerdir?";
    
    return prompt;
  }
}
