import 'package:flutter/material.dart';
import '../services/crops_service.dart';
import '../models/crop_guide.dart';
import '../models/city_data.dart';
import '../data/crop_database.dart';
import '../services/yield_calculator_service.dart';
import '../models/crop_price_data.dart';
import '../services/market_price_service.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../services/reminders_service.dart';
import '../theme/app_theme.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _crops = [];
  late AnimationController _fabController;

  @override
  bool get wantKeepAlive => true;
  late Animation<double> _fabAnimation;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Cache için static değişkenler (performans optimizasyonu)
  static List<String>? _cachedAllCrops;
  static List<String>? _cachedSortedCrops;
  static List<CityData>? _cachedAllCities;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    _fabController.forward();
    _loadCrops();
  }

  // Mahsulleri yükle
  Future<void> _loadCrops({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final crops = await CropsService.getUserCrops(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _crops.clear();
          _crops.addAll(crops);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _addCrop() {
    final TextEditingController varietyController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController cropSearchController = TextEditingController();
    final TextEditingController citySearchController = TextEditingController();
    final TextEditingController areaController = TextEditingController();
    String? selectedCropName;
    String? selectedCityName;
    DateTime? selectedPlantingDate;
    DateTime? selectedHarvestDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Mahsul Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mahsul seçimi
                    const Text(
                      'Mahsul Seçimi *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cropSearchController,
                      decoration: InputDecoration(
                        hintText: 'Mahsul ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: selectedCropName != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  cropSearchController.clear();
                                  setDialogState(() {
                                    selectedCropName = null;
                                    selectedHarvestDate = null;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                      onTap: () {
                        final nestedSearchController = TextEditingController(text: cropSearchController.text);
                        showDialog(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setNestedState) => AlertDialog(
                              title: const Text('Mahsul Seç'),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 400,
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: nestedSearchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Mahsul ara...',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setNestedState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: _buildCropList(
                                        nestedSearchController.text,
                                        (cropName) {
                                          selectedCropName = cropName;
                                          cropSearchController.text = cropName;
                                          Navigator.pop(context);
                                          // Otomatik hasat tarihi hesapla
                                          if (selectedPlantingDate != null && selectedCityName != null) {
                                            final harvestInfo = AIService.calculateHarvestTime(
                                              cropName,
                                              selectedCityName!,
                                              selectedPlantingDate!,
                                            );
                                            setDialogState(() {
                                              selectedHarvestDate = harvestInfo['harvestDate'] as DateTime?;
                                            });
                                          } else {
                                            setDialogState(() {});
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (selectedCropName != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              selectedCropName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Ekim Alanı (Metrekare) *',
                        border: OutlineInputBorder(),
                        hintText: 'Örn: 1000',
                        prefixIcon: Icon(Icons.square_foot),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Şehir seçimi
                    const Text(
                      'Şehir Seçimi *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: citySearchController,
                      decoration: InputDecoration(
                        hintText: 'Şehir ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: selectedCityName != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  citySearchController.clear();
                                  setDialogState(() {
                                    selectedCityName = null;
                                    selectedHarvestDate = null;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onTap: () {
                        final nestedCitySearchController = TextEditingController(text: citySearchController.text);
                        showDialog(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setNestedState) => AlertDialog(
                              title: const Text('Şehir Seç'),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 400,
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: nestedCitySearchController,
                                      decoration: const InputDecoration(
                                        hintText: 'Şehir ara...',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setNestedState(() {});
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: _buildCityList(
                                        nestedCitySearchController.text,
                                        (cityName) {
                                          selectedCityName = cityName;
                                          citySearchController.text = cityName;
                                          Navigator.pop(context);
                                          // Otomatik hasat tarihi hesapla
                                          if (selectedPlantingDate != null && selectedCropName != null) {
                                            final harvestInfo = AIService.calculateHarvestTime(
                                              selectedCropName!,
                                              cityName,
                                              selectedPlantingDate!,
                                            );
                                            setDialogState(() {
                                              selectedHarvestDate = harvestInfo['harvestDate'] as DateTime?;
                                            });
                                          } else {
                                            setDialogState(() {});
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (selectedCityName != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_city, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              selectedCityName!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: varietyController,
                      decoration: const InputDecoration(
                        labelText: 'Çeşit (Opsiyonel)',
                        border: OutlineInputBorder(),
                        hintText: 'Örn: Cherry, Sivri',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedPlantingDate == null
                            ? 'Ekim Tarihi *'
                            : 'Ekim Tarihi: ${selectedPlantingDate!.day}/${selectedPlantingDate!.month}/${selectedPlantingDate!.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(), // Gelecek tarih seçilemez, sadece bugün ve geçmiş
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedPlantingDate = date;
                            // Otomatik hasat tarihi hesapla
                            if (selectedCropName != null && selectedCityName != null) {
                              final harvestInfo = AIService.calculateHarvestTime(
                                selectedCropName!,
                                selectedCityName!,
                                date,
                              );
                              selectedHarvestDate = harvestInfo['harvestDate'] as DateTime?;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedHarvestDate != null ? Colors.orange.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedHarvestDate != null ? Colors.orange.shade200 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.agriculture,
                                color: selectedHarvestDate != null ? Colors.orange.shade700 : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedHarvestDate == null
                                    ? 'Beklenen Hasat Tarihi (Otomatik)'
                                    : 'Beklenen Hasat Tarihi: ${selectedHarvestDate!.day}/${selectedHarvestDate!.month}/${selectedHarvestDate!.year}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedHarvestDate != null ? Colors.orange.shade700 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (selectedHarvestDate != null && selectedCropName != null && selectedCityName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '💡 Bu tarih seçilen mahsul ve şehre göre otomatik hesaplandı.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
                        border: OutlineInputBorder(),
                        hintText: 'Ek bilgiler...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCropName != null && 
                        selectedCityName != null &&
                        selectedPlantingDate != null &&
                        areaController.text.isNotEmpty) {
                      
                      try {
                        final parsedAreaSqm = double.tryParse(areaController.text) ?? 1000.0;
                        await CropsService.addCrop(
                          name: selectedCropName!,
                          variety: varietyController.text.isNotEmpty ? varietyController.text : null,
                          plantingDate: selectedPlantingDate!,
                          expectedHarvestDate: selectedHarvestDate,
                          city: selectedCityName!,
                          notes: notesController.text.isNotEmpty ? notesController.text : null,
                          areaSqm: parsedAreaSqm,
                        );
                        
                        // Yeni eklenen mahsulü al (hasat hatırlatıcıları için)
                        final crops = await CropsService.getUserCrops(forceRefresh: true);
                        final newCrop = crops.firstWhere(
                          (c) => c['name'] == selectedCropName && 
                                 c['city'] == selectedCityName,
                          orElse: () => {},
                        );
                        
                        // Hasat hatırlatıcılarını zamanla
                        if (newCrop.isNotEmpty && selectedHarvestDate != null) {
                          try {
                            await NotificationService.scheduleHarvestReminder(
                              cropId: newCrop['id'],
                              cropName: selectedCropName!,
                              harvestDate: selectedHarvestDate!,
                            );
                          } catch (e) {
                            print('Hasat hatırlatıcısı zamanlanamadı: $e');
                          }
                        }
                        
                        Navigator.of(context).pop();
                        await _loadCrops(forceRefresh: true); // Mahsulleri yeniden yükle (cache'i bypass et)
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${selectedCropName!} mahsulü başarıyla eklendi!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen mahsul, şehir ve ekim tarihini seçin'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Mahsul silme fonksiyonu
  Future<void> _deleteCrop(Map<String, dynamic> crop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mahsulü Sil'),
        content: Text('${crop['name']} mahsulünü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Bildirimleri iptal et
        await NotificationService.cancelCropNotifications(crop['id']);
        await CropsService.deleteCrop(crop['id']);
        await _loadCrops(forceRefresh: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${crop['name']} mahsulü silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Mahsul detaylarını göster (Geliştirilmiş şık tasarım)
  void _showCropDetails(Map<String, dynamic> crop) {
    final plantingDate = DateTime.tryParse(crop['planting_date'] ?? '');
    final harvestDate = DateTime.tryParse(crop['expected_harvest_date'] ?? '');
    
    // Kaç gün oldu hesapla
    String daysSincePlanting = 'Bilinmiyor';
    int daysSince = 0;
    if (plantingDate != null) {
      daysSince = DateTime.now().difference(plantingDate).inDays;
      daysSincePlanting = '$daysSince gün';
    }
    
    // Beklenen hasat tarihi ve kalan süre
    String harvestInfo = 'Belirtilmemiş';
    String daysToHarvestText = '';
    Color harvestColor = Colors.grey;
    if (harvestDate != null) {
      final daysToHarvest = harvestDate.difference(DateTime.now()).inDays;
      if (daysToHarvest > 0) {
        harvestInfo = _formatDate(crop['expected_harvest_date']);
        daysToHarvestText = '$daysToHarvest gün kaldı';
        harvestColor = daysToHarvest > 30 ? Colors.green : Colors.orange;
      } else if (daysToHarvest == 0) {
        harvestInfo = _formatDate(crop['expected_harvest_date']);
        daysToHarvestText = 'Bugün hasat!';
        harvestColor = Colors.red;
      } else {
        harvestInfo = _formatDate(crop['expected_harvest_date']);
        daysToHarvestText = '${-daysToHarvest} gün geçti';
        harvestColor = Colors.red.shade700;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık kısmı
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop['name'] ?? 'Mahsul',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (crop['city'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    crop['city'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hasat bilgisi (Öne çıkan)
                      if (harvestDate != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: harvestColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: harvestColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.agriculture,
                                color: harvestColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                daysToHarvestText,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: harvestColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Beklenen Hasat: $harvestInfo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Detay bilgileri
                      _buildDetailCard(
                        Icons.calendar_today,
                        'Ekim Tarihi',
                        _formatDate(crop['planting_date']),
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        Icons.timer,
                        'Ekimden Bu Yana',
                        daysSincePlanting,
                        Colors.purple,
                      ),
                      if (crop['area_sqm'] != null && crop['area_sqm'] > 0) ...[
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          Icons.square_foot,
                          'Ekim Alanı',
                          '${crop['area_sqm']} m²',
                          Colors.brown,
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<CropPriceData?>(
                          future: MarketPriceService.getLivePriceForCrop(
                            CropDatabase.getCropByName(crop['name'] ?? '')?.id ?? 'crop_wheat'
                          ),
                          builder: (context, priceSnapshot) {
                            final yieldResult = YieldCalculatorService.calculateYield(
                              crop: CropDatabase.getCropByName(crop['name'] ?? '') ?? CropDatabase.getCropById('crop_wheat')!,
                              areaInSqMeters: double.tryParse(crop['area_sqm'].toString()) ?? 0,
                            );

                            String revenueText = '';
                            if (priceSnapshot.hasData && priceSnapshot.data != null) {
                              final priceInfo = priceSnapshot.data!;
                              final estimatedRevenueMin = yieldResult.finalExpectedYieldKg * priceInfo.minPricePerKg;
                              final estimatedRevenueMax = yieldResult.finalExpectedYieldKg * priceInfo.maxPricePerKg;
                              
                              // Para Formatı (. kisaimi)
                              String formatCurrency(double val) {
                                if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(2)} Milyon ₺';
                                if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)} Bin ₺';
                                return '${val.toStringAsFixed(0)} ₺';
                              }

                              revenueText = '${formatCurrency(estimatedRevenueMin)} - ${formatCurrency(estimatedRevenueMax)}\n(Adana Hal Ort.)';
                            } else {
                              revenueText = 'Fiyat Verisi Bekleniyor...';
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.scale, color: Colors.amber.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tahmini Hasat',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    yieldResult.getFormattedEstimatedYield(),
                                    style: TextStyle(fontSize: 18, color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined, color: Colors.green.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Güncel Piyasa Değeri',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  priceSnapshot.connectionState == ConnectionState.waiting 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(
                                        revenueText,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                      ),
                                    
                                  if (priceSnapshot.hasData && priceSnapshot.data != null) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAiFinancialAdvisor(
                                          context, 
                                          crop,
                                          yieldResult.finalExpectedYieldKg,
                                          yieldResult.finalExpectedYieldKg * priceSnapshot.data!.minPricePerKg,
                                          yieldResult.finalExpectedYieldKg * priceSnapshot.data!.maxPricePerKg,
                                        ),
                                        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                        label: const Text(
                                          'Yapay Zeka Analizi İste',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo.shade600,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          )
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                      if (crop['variety'] != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          Icons.category,
                          'Çeşit',
                          crop['variety'],
                          Colors.orange,
                        ),
                      ],
                      if (crop['notes'] != null && crop['notes'].isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          Icons.note,
                          'Notlar',
                          crop['notes'],
                          Colors.teal,
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Hatırlatıcılar bölümü
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: RemindersService.getCropReminders(crop['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final reminders = snapshot.data ?? [];
                          final activeReminders = reminders.where((r) => !(r['is_completed'] ?? false)).toList();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.notifications_active, color: Colors.orange.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Hatırlatıcılar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showAddReminderDialog(crop),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ekle'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (activeReminders.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Henüz hatırlatıcı eklenmemiş',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...activeReminders.map((reminder) => _buildReminderCard(reminder, crop)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Alt butonlar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Kapat'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddReminderDialog(crop),
                          icon: const Icon(Icons.notifications),
                          label: const Text('Hatırlatıcı'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              await CropsService.addCropToFavorites(crop['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${crop['name']} favorilere eklendi'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text('Favori'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAiFinancialAdvisor(BuildContext context, Map<String, dynamic> crop, double expectedYieldKg, double minRev, double maxRev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.indigo.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Finansal Danışman',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Piyasa, Verim ve Strateji Analizi',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: AIService.getFinancialAdvisory(
                  cropName: crop['name'] ?? 'Bilinmiyor',
                  expectedYieldKg: expectedYieldKg,
                  minRevenue: minRev,
                  maxRevenue: maxRev,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('Türkiye Borsa verileri analiz ediliyor...', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Danışmanlığa şu an ulaşılamıyor.'));
                  }

                  // Basit markdown parser (sadece kalın - bold - text render icin)
                  List<TextSpan> _parseMarkdown(String text) {
                    final List<TextSpan> spans = [];
                    final pattern = RegExp(r'\*\*(.*?)\*\*');
                    int lastMatchEnd = 0;

                    for (final match in pattern.allMatches(text)) {
                      if (match.start > lastMatchEnd) {
                        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
                      }
                      spans.add(TextSpan(
                        text: match.group(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ));
                      lastMatchEnd = match.end;
                    }
                    if (lastMatchEnd < text.length) {
                      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
                    }
                    return spans;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                        children: _parseMarkdown(snapshot.data!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Detay kartı widget'ı
  Widget _buildDetailCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarih formatlama fonksiyonu
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Belirtilmemiş';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Mahsul listesi widget'ı (Cache ile optimize edilmiş)
  Widget _buildCropList(String searchQuery, Function(String) onCropSelected) {
    // İlk yüklemede cache'e al
    if (_cachedAllCrops == null) {
      _cachedAllCrops = CropGuide.getCropGuides().keys.toList();
      // Alfabetik sıralamayı bir kez yap ve cache'le
      _cachedSortedCrops = List<String>.from(_cachedAllCrops!);
      _cachedSortedCrops!.sort((a, b) {
        String normalize(String str) {
          return str
              .replaceAll('İ', 'I')
              .replaceAll('ı', 'i')
              .replaceAll('Ş', 'S')
              .replaceAll('ş', 's')
              .replaceAll('Ğ', 'G')
              .replaceAll('ğ', 'g')
              .replaceAll('Ü', 'U')
              .replaceAll('ü', 'u')
              .replaceAll('Ö', 'O')
              .replaceAll('ö', 'o')
              .replaceAll('Ç', 'C')
              .replaceAll('ç', 'c')
              .toLowerCase();
        }
        return normalize(a).compareTo(normalize(b));
      });
    }
    
    // Filtreleme (cache'lenmiş listeden)
    final filteredCrops = searchQuery.isEmpty
        ? _cachedSortedCrops!
        : _cachedSortedCrops!.where((crop) => crop.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    if (filteredCrops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Mahsul bulunamadı'),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCrops.length,
      itemBuilder: (context, index) {
        final cropName = filteredCrops[index];
        final cropGuide = CropGuide.getCropGuides()[cropName];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.eco, color: Colors.green.shade700, size: 20),
            ),
            title: Text(
              cropName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: cropGuide != null
                ? Text('Hasat: ${cropGuide.harvestTime}')
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onCropSelected(cropName),
          ),
        );
      },
    );
  }

  // Modern ve Şık Mahsul Kartı Tasarımı
  Widget _buildCropCard(Map<String, dynamic> crop, int index) {
    final plantingDate = DateTime.tryParse(crop['planting_date'] ?? '');
    final harvestDate = DateTime.tryParse(crop['expected_harvest_date'] ?? '');
    
    // Durum Belirleme
    String statusText = 'Bilinmiyor';
    Color statusColor = AppTheme.textSecondary;
    Color statusBgColor = AppTheme.textSecondary.withValues(alpha: 0.1);
    
    if (harvestDate != null) {
      final daysToHarvest = harvestDate.difference(DateTime.now()).inDays;
      if (daysToHarvest > 30) {
        statusText = '$daysToHarvest gün kaldı';
        statusColor = AppTheme.successColor;
        statusBgColor = AppTheme.successColor.withValues(alpha: 0.1);
      } else if (daysToHarvest > 0) {
        statusText = '$daysToHarvest gün kaldı';
        statusColor = AppTheme.warningColor;
        statusBgColor = AppTheme.warningColor.withValues(alpha: 0.1);
      } else if (daysToHarvest == 0) {
        statusText = 'Hasat Zamanı!';
        statusColor = AppTheme.errorColor;
        statusBgColor = AppTheme.errorColor.withValues(alpha: 0.1);
      } else {
        statusText = 'Hasat Gecikti';
        statusColor = AppTheme.errorColor;
        statusBgColor = AppTheme.errorColor.withValues(alpha: 0.1);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCropDetails(crop),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İkon Alanı
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Başlık ve Lokasyon
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crop['name'] ?? 'Mahsul',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                crop['city'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menü Butonu
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz, color: AppTheme.textLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        elevation: 4,
                        onSelected: (value) async {
                          switch (value) {
                             case 'details':
                              _showCropDetails(crop);
                              break;
                             case 'favorite':
                               try {
                                 await CropsService.addCropToFavorites(crop['id']);
                                 if (mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Favorilere eklendi'), backgroundColor: AppTheme.successColor),
                                   );
                                 }
                               } catch (e) {
                                 // Hata yönetimi
                               }
                               break;
                             case 'delete':
                              _deleteCrop(crop);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                                SizedBox(width: 12),
                                Text('Detaylar', style: TextStyle(color: AppTheme.textPrimary)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border, size: 20, color: AppTheme.warningColor),
                                SizedBox(width: 12),
                                Text('Favori', style: TextStyle(color: AppTheme.textPrimary)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                                SizedBox(width: 12),
                                Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bilgi Çipleri
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (crop['variety'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          crop['variety'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    if (crop['area_sqm'] != null && crop['area_sqm'] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.scale_outlined, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              YieldCalculatorService.calculateYield(
                                crop: CropDatabase.getCropByName(crop['name'] ?? '') ?? CropDatabase.getCropById('crop_wheat')!,
                                areaInSqMeters: double.tryParse(crop['area_sqm'].toString()) ?? 0,
                              ).getFormattedEstimatedYield(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Şehir listesi widget'ı (Cache ile optimize edilmiş)
  Widget _buildCityList(String searchQuery, Function(String) onCitySelected) {
    // İlk yüklemede cache'e al (zaten alfabetik sıralı geliyor)
    _cachedAllCities ??= CityData.getTurkishCities();
    
    // Filtreleme (cache'lenmiş listeden)
    final filteredCities = searchQuery.isEmpty
        ? _cachedAllCities!
        : _cachedAllCities!.where((city) =>
            city.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            city.region.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    if (filteredCities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Şehir bulunamadı'),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCities.length,
      itemBuilder: (context, index) {
        final city = filteredCities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.location_city, color: Colors.blue.shade700, size: 20),
            ),
            title: Text(
              city.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(city.region),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onCitySelected(city.name),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(
                    'Mahsullerim',
                    style: AppTheme.modernTitle.copyWith(fontSize: 32),
                  ),
                  centerTitle: false,
                  backgroundColor: AppTheme.backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  pinned: true,
                  floating: true,
                  expandedHeight: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                        onPressed: () => _loadCrops(forceRefresh: true),
                        tooltip: 'Yenile',
                      ),
                    ),
                  ],
                ),
                
                if (_errorMessage != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Hata: $_errorMessage', style: const TextStyle(color: AppTheme.errorColor)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadCrops(forceRefresh: true),
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_crops.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.eco_outlined, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Henüz mahsul yok',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'İlk mahsulünüzü eklemek için + butonuna basın',
                            style: TextStyle(color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), // Bottom padding for FAB and Floating Nav
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final crop = _crops[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 400 + (index * 50)),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: _buildCropCard(crop, index),
                                ),
                              );
                            },
                          );
                        },
                        childCount: _crops.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        child: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton(
              onPressed: _addCrop,
              elevation: 4,
              backgroundColor: AppTheme.primaryColor,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          );
        },
      ),
      ),
    );
  }

  // Hatırlatıcı ekleme dialogu
  void _showAddReminderDialog(Map<String, dynamic> crop) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;
    DateTime? selectedTime;
    String selectedType = 'other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Hatırlatıcı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık *',
                    hintText: 'Örn: İlaçlama, Sulama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Ek bilgiler...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Hatırlatıcı Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'spraying', child: Text('İlaçlama')),
                    DropdownMenuItem(value: 'watering', child: Text('Sulama')),
                    DropdownMenuItem(value: 'fertilizing', child: Text('Gübreleme')),
                    DropdownMenuItem(value: 'pruning', child: Text('Budama')),
                    DropdownMenuItem(value: 'harvesting', child: Text('Hasat')),
                    DropdownMenuItem(value: 'other', child: Text('Diğer')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value ?? 'other';
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(selectedDate == null ? 'Tarih Seç' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedTime = DateTime(
                                selectedDate?.year ?? DateTime.now().year,
                                selectedDate?.month ?? DateTime.now().month,
                                selectedDate?.day ?? DateTime.now().day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime == null ? 'Saat Seç' : '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen başlık girin'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (selectedDate == null || selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tarih ve saat seçin'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final reminderDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                try {
                  await RemindersService.addReminder(
                    cropId: crop['id'],
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    reminderDate: reminderDateTime,
                    reminderType: selectedType,
                  );

                  Navigator.of(context).pop();
                  // Detay ekranını yenile
                  Navigator.of(context).pop();
                  _showCropDetails(crop);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hatırlatıcı başarıyla eklendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  // Hatırlatıcı kartı widget'ı
  Widget _buildReminderCard(Map<String, dynamic> reminder, Map<String, dynamic> crop) {
    final reminderDate = DateTime.tryParse(reminder['reminder_date'] ?? '');
    final isPast = reminderDate != null && reminderDate.isBefore(DateTime.now());
    
    String typeText = 'Diğer';
    IconData typeIcon = Icons.notifications;
    Color typeColor = Colors.grey;

    switch (reminder['reminder_type']) {
      case 'spraying':
        typeText = 'İlaçlama';
        typeIcon = Icons.medical_services;
        typeColor = Colors.red;
        break;
      case 'watering':
        typeText = 'Sulama';
        typeIcon = Icons.water_drop;
        typeColor = Colors.blue;
        break;
      case 'fertilizing':
        typeText = 'Gübreleme';
        typeIcon = Icons.eco;
        typeColor = Colors.brown;
        break;
      case 'pruning':
        typeText = 'Budama';
        typeIcon = Icons.content_cut;
        typeColor = Colors.orange;
        break;
      case 'harvesting':
        typeText = 'Hasat';
        typeIcon = Icons.agriculture;
        typeColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(typeIcon, color: typeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'] ?? 'Hatırlatıcı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPast ? Colors.grey : Colors.black87,
                  ),
                ),
                if (reminder['description'] != null && reminder['description'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      typeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reminderDate != null
                          ? '${reminderDate.day}/${reminderDate.month}/${reminderDate.year} ${reminderDate.hour}:${reminderDate.minute.toString().padLeft(2, '0')}'
                          : 'Tarih belirtilmemiş',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            color: Colors.green,
            onPressed: () async {
              try {
                await RemindersService.completeReminder(reminder['id']);
                Navigator.of(context).pop();
                _showCropDetails(crop);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hatırlatıcı tamamlandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

