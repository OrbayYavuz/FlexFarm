import '../models/crop_yield_data.dart';

class CropDatabase {
  static const List<CropData> allCrops = [
    // --- TAHILLAR ---
    CropData(
      id: 'crop_wheat',
      name: 'Buğday',
      scientificName: 'Triticum',
      baseYieldPerDecare: 400.0,
      averageGrowthDays: 240,
      category: 'Tahıl',
    ),
    CropData(
      id: 'crop_corn',
      name: 'Mısır',
      scientificName: 'Zea mays',
      baseYieldPerDecare: 1100.0,
      averageGrowthDays: 130,
      category: 'Tahıl',
    ),
    CropData(
      id: 'crop_barley',
      name: 'Arpa',
      scientificName: 'Hordeum vulgare',
      baseYieldPerDecare: 350.0,
      averageGrowthDays: 200,
      category: 'Tahıl',
    ),

    // --- ENDÜSTRİ BİTKİLERİ ---
    CropData(
      id: 'crop_sunflower',
      name: 'Ayçiçeği',
      scientificName: 'Helianthus annuus',
      baseYieldPerDecare: 250.0,
      averageGrowthDays: 120,
      category: 'Endüstri Bitkisi',
    ),
    CropData(
      id: 'crop_cotton',
      name: 'Pamuk',
      scientificName: 'Gossypium',
      baseYieldPerDecare: 500.0,
      averageGrowthDays: 160,
      category: 'Endüstri Bitkisi',
    ),
    CropData(
      id: 'crop_sugar_beet',
      name: 'Şeker Pancarı',
      scientificName: 'Beta vulgaris',
      baseYieldPerDecare: 6500.0,
      averageGrowthDays: 180,
      category: 'Endüstri Bitkisi',
    ),
    CropData(
      id: 'crop_tobacco',
      name: 'Tütün',
      scientificName: 'Nicotiana tabacum',
      baseYieldPerDecare: 150.0,
      averageGrowthDays: 120,
      category: 'Endüstri Bitkisi',
    ),
    CropData(
      id: 'crop_tea',
      name: 'Çay',
      scientificName: 'Camellia sinensis',
      baseYieldPerDecare: 1200.0, // Yaş çay
      averageGrowthDays: 180,
      category: 'Endüstri Bitkisi',
    ),

    // --- SEBZELER ---
    CropData(
      id: 'crop_tomato',
      name: 'Domates',
      scientificName: 'Solanum lycopersicum',
      baseYieldPerDecare: 7000.0,
      averageGrowthDays: 100,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_pepper',
      name: 'Biber', // Kırmızı/Yeşil Biber ortalama
      scientificName: 'Capsicum annuum',
      baseYieldPerDecare: 3500.0,
      averageGrowthDays: 90,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_red_pepper',
      name: 'Kırmızı Biber',
      scientificName: 'Capsicum',
      baseYieldPerDecare: 3500.0,
      averageGrowthDays: 90,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_potato',
      name: 'Patates',
      scientificName: 'Solanum tuberosum',
      baseYieldPerDecare: 4000.0,
      averageGrowthDays: 120,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_onion',
      name: 'Soğan',
      scientificName: 'Allium cepa',
      baseYieldPerDecare: 4000.0,  
      averageGrowthDays: 150,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_cucumber',
      name: 'Salatalık',
      scientificName: 'Cucumis sativus',
      baseYieldPerDecare: 5000.0,
      averageGrowthDays: 70,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_lettuce',
      name: 'Marul',
      scientificName: 'Lactuca sativa',
      baseYieldPerDecare: 2500.0,
      averageGrowthDays: 60,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_spinach',
      name: 'Ispanak',
      scientificName: 'Spinacia oleracea',
      baseYieldPerDecare: 1500.0,
      averageGrowthDays: 45,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_eggplant',
      name: 'Patlıcan',
      scientificName: 'Solanum melongena',
      baseYieldPerDecare: 4500.0,
      averageGrowthDays: 90,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_zucchini',
      name: 'Kabak',
      scientificName: 'Cucurbita pepo',
      baseYieldPerDecare: 4000.0,
      averageGrowthDays: 70,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_carrot',
      name: 'Havuç',
      scientificName: 'Daucus carota',
      baseYieldPerDecare: 3500.0,
      averageGrowthDays: 90,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_beans',
      name: 'Fasulye',
      scientificName: 'Phaseolus vulgaris',
      baseYieldPerDecare: 1200.0, // Taze fasulye
      averageGrowthDays: 80,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_cabbage',
      name: 'Lahana',
      scientificName: 'Brassica oleracea',
      baseYieldPerDecare: 4500.0,
      averageGrowthDays: 120,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_cauliflower',
      name: 'Karnabahar',
      scientificName: 'Brassica oleracea var. botrytis',
      baseYieldPerDecare: 2500.0,
      averageGrowthDays: 120,
      category: 'Sebze',
    ),
    CropData(
      id: 'crop_broccoli',
      name: 'Brokoli',
      scientificName: 'Brassica oleracea var. italica',
      baseYieldPerDecare: 1500.0,
      averageGrowthDays: 100,
      category: 'Sebze',
    ),

    // --- YEŞİLLİK VE OTLAR ---
    CropData(
      id: 'crop_parsley',
      name: 'Maydanoz',
      scientificName: 'Petroselinum crispum',
      baseYieldPerDecare: 1000.0,
      averageGrowthDays: 80,
      category: 'Yeşillik',
    ),
    CropData(
      id: 'crop_basil',
      name: 'Fesleğen',
      scientificName: 'Ocimum basilicum',
      baseYieldPerDecare: 800.0,
      averageGrowthDays: 80,
      category: 'Yeşillik',
    ),

    // --- MEYVELER VE AĞAÇLAR ---
    CropData(
      id: 'crop_olive',
      name: 'Zeytin',
      scientificName: 'Olea europaea',
      baseYieldPerDecare: 600.0, // Yetişkin bahçe (kg/dekar)
      averageGrowthDays: 200, // Çiçeklenmeden hasada
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_grape',
      name: 'Üzüm',
      scientificName: 'Vitis vinifera',
      baseYieldPerDecare: 1500.0,
      averageGrowthDays: 150,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_fig',
      name: 'İncir',
      scientificName: 'Ficus carica',
      baseYieldPerDecare: 800.0,
      averageGrowthDays: 120,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_pomegranate',
      name: 'Nar',
      scientificName: 'Punica granatum',
      baseYieldPerDecare: 1200.0,
      averageGrowthDays: 180,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_citrus',
      name: 'Turunçgil',
      scientificName: 'Citrus',
      baseYieldPerDecare: 4000.0,
      averageGrowthDays: 240,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_avocado',
      name: 'Avokado',
      scientificName: 'Persea americana',
      baseYieldPerDecare: 1000.0,
      averageGrowthDays: 240,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_mango',
      name: 'Mango',
      scientificName: 'Mangifera indica',
      baseYieldPerDecare: 1500.0,
      averageGrowthDays: 150,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_hazelnut',
      name: 'Fındık',
      scientificName: 'Corylus avellana',
      baseYieldPerDecare: 150.0, // Kabuklu fındık
      averageGrowthDays: 180,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_pistachio',
      name: 'Antep Fıstığı',
      scientificName: 'Pistacia vera',
      baseYieldPerDecare: 120.0,
      averageGrowthDays: 180,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_apricot',
      name: 'Kayısı',
      scientificName: 'Prunus armeniaca',
      baseYieldPerDecare: 1500.0,
      averageGrowthDays: 120,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_peach',
      name: 'Şeftali',
      scientificName: 'Prunus persica',
      baseYieldPerDecare: 2000.0,
      averageGrowthDays: 130,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_cherry',
      name: 'Kiraz',
      scientificName: 'Prunus avium',
      baseYieldPerDecare: 800.0,
      averageGrowthDays: 90,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_pear',
      name: 'Armut',
      scientificName: 'Pyrus communis',
      baseYieldPerDecare: 2500.0,
      averageGrowthDays: 150,
      category: 'Meyve',
    ),
    CropData(
      id: 'crop_apple',
      name: 'Elma',
      scientificName: 'Malus domestica',
      baseYieldPerDecare: 3000.0,
      averageGrowthDays: 160,
      category: 'Meyve',
    ),
  ];

  static CropData? getCropById(String id) {
    try {
      return allCrops.firstWhere((crop) => crop.id == id);
    } catch (e) {
      return null;
    }
  }

  static CropData? getCropByName(String name) {
    try {
      return allCrops.firstWhere((crop) => crop.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<CropData> getCropsByCategory(String category) {
    return allCrops.where((crop) => crop.category == category).toList();
  }
}

class CommonModifiers {
  static const YieldModifier dripIrrigation = YieldModifier(
    id: 'mod_irrigation_drip',
    name: 'Damlama Sulama Sistemi',
    type: YieldModifierType.irrigation,
    multiplier: 1.15,
    description: 'Etkili su kullanımı verimi artırır',
  );

  static const YieldModifier poorSoil = YieldModifier(
    id: 'mod_soil_poor',
    name: 'Düşük Toprak Kalitesi',
    type: YieldModifierType.soilQuality,
    multiplier: 0.85,
    description: 'Organik madde eksikliği',
  );
  
  static const YieldModifier organicFertilizer = YieldModifier(
    id: 'mod_fert_organic',
    name: 'Organik Gübreleme',
    type: YieldModifierType.fertilizer,
    multiplier: 1.05,
    description: 'Düzenli organik gübre takviyesi',
  );
}
