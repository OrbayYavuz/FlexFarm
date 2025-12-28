import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/city_data.dart';
import '../models/crop_guide.dart';
import '../services/ai_service.dart';

class AISupportScreen extends StatefulWidget {
  const AISupportScreen({super.key});

  @override
  State<AISupportScreen> createState() => _AISupportScreenState();
}

class _AISupportScreenState extends State<AISupportScreen> with TickerProviderStateMixin {
  String? selectedCity;
  List<String> recommendedCrops = [];
  String? selectedCrop;
  List<String> favoriteCrops = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  static const String _storageKey = 'ai_support_favorites';
  static const String _cityStorageKey = 'ai_support_selected_city';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _loadFavorites();
    _loadSelectedCity();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedFavorites = prefs.getStringList(_storageKey);
    if (storedFavorites != null) {
      setState(() {
        favoriteCrops = storedFavorites;
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, favoriteCrops);
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedCity = prefs.getString(_cityStorageKey);
    if (storedCity != null) {
      _selectCity(storedCity);
    }
  }

  Future<void> _saveSelectedCity(String? city) async {
    final prefs = await SharedPreferences.getInstance();
    if (city != null) {
      await prefs.setString(_cityStorageKey, city);
    } else {
      await prefs.remove(_cityStorageKey);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  List<CityData> get _filteredCities {
    final cities = CityData.getTurkishCities();
    if (_searchQuery.isEmpty) {
      return cities;
    }
    return cities.where((city) {
      return city.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             city.region.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _selectCity(String cityName) {
    setState(() {
      selectedCity = cityName;
      selectedCrop = null;
      final city = CityData.getTurkishCities().firstWhere((c) => c.name == cityName);
      recommendedCrops = city.suitableCrops;
    });
    _saveSelectedCity(cityName);
  }

  void _selectCrop(String cropName) {
    setState(() {
      selectedCrop = cropName;
    });
  }

  void _addToFavorites() {
    if (selectedCrop != null && !favoriteCrops.contains(selectedCrop)) {
      // AI ile hasat zamanı hesapla
      final harvestInfo = AIService.calculateHarvestTime(
        selectedCrop!,
        selectedCity!,
        DateTime.now(),
      );
      
      setState(() {
        favoriteCrops.add(selectedCrop!);
      });
      _saveFavorites();
      
      // Detaylı başarı mesajı göster
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.eco, color: Colors.green),
                const SizedBox(width: 8),
                Text('$selectedCrop Eklendi!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Favorilerinize başarıyla eklendi'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌱 Tahmini Hasat Bilgileri',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('⏰ Hasat Süresi: ${harvestInfo['estimatedHarvest']}'),
                      Text('📅 Tahmini Hasat: ${_formatDate(harvestInfo['harvestDate'])}'),
                      Text('🎯 Güven Seviyesi: ${harvestInfo['confidence']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 İpucu: Mahsule tıklayarak büyütme ipuçlarını görebilirsiniz!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    } else if (selectedCrop != null && favoriteCrops.contains(selectedCrop)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedCrop zaten favorilerinizde!'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'AI Destek',
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
                  icon: Stack(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppTheme.primaryColor),
                      if (favoriteCrops.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Favorilerim'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: favoriteCrops.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'Henüz favori mahsulünüz yok',
                                          style: TextStyle(fontSize: 16, color: Colors.grey),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Mahsul seçip "Favorilere Ekle" butonuna basın',
                                          style: TextStyle(fontSize: 14, color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: favoriteCrops.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        leading: const Icon(Icons.favorite, color: Colors.red),
                                        title: Text(favoriteCrops[index]),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            final removedCrop = favoriteCrops[index];
                                            setState(() {
                                              favoriteCrops.removeAt(index);
                                            });
                                            _saveFavorites();
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('$removedCrop favorilerden kaldırıldı'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Kapat'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  tooltip: 'Favorilerim',
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Şehrinizi Seçin',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'AI, şehrinizin iklim ve toprak özelliklerine göre en uygun mahsulleri önerecek',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Şehir Seçim Barı (Her zaman görünür)
                        GestureDetector(
                          onTap: () => _showCitySelectionModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: selectedCity != null 
                                  ? AppTheme.primaryColor.withValues(alpha: 0.5) 
                                  : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedCity != null ? AppTheme.primaryColor : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_city,
                                    color: selectedCity != null ? Colors.white : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedCity ?? 'Şehir Seçiniz',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: selectedCity != null ? AppTheme.textPrimary : Colors.grey.shade600,
                                        ),
                                      ),
                                      if (selectedCity != null)
                                        Text(
                                          'Tıklayarak değiştirebilirsiniz',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Seçili şehir varsa içeriği göster
                        if (selectedCity != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCityInfo(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Önerilen mahsuller
                          const Text(
                            'Önerilen Mahsuller',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: recommendedCrops.length,
                            itemBuilder: (context, index) {
                              final crop = recommendedCrops[index];
                              final isSelected = selectedCrop == crop;
                              return GestureDetector(
                                onTap: () => _selectCrop(crop),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
                                        blurRadius: isSelected ? 12 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.eco_rounded,
                                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          crop,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Seçilen mahsul detayları
                          if (selectedCrop != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.eco_rounded,
                                          color: AppTheme.secondaryColor,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        selectedCrop!,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildCropDetails(),
                                  const SizedBox(height: 24),
                                  _buildGrowingTips(),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _addToFavorites,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.favorite),
                                          SizedBox(width: 8),
                                          Text(
                                            'Favorilere Ekle',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
        ],
      ),
    );
  }

  Widget _buildCityInfo() {
    final city = CityData.getTurkishCities().firstWhere((c) => c.name == selectedCity);
    return Column(
      children: [
        _buildInfoRow('Bölge', city.region),
        _buildInfoRow('İklim', city.climate),
        _buildInfoRow('Toprak', city.soilType),
        const SizedBox(height: 12),
        const Text(
          'İklim Bilgileri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...city.climateInfo.entries.map((entry) => 
          _buildInfoRow(entry.key, entry.value)
        ),
      ],
    );
  }

  void _showCitySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          String currentQuery = _searchController.text.trim();

          String normalize(String text) {
            return text.toLowerCase()
              .replaceAll('ğ', 'g')
              .replaceAll('ü', 'u')
              .replaceAll('ş', 's')
              .replaceAll('ı', 'i')
              .replaceAll('i', 'i')
              .replaceAll('ö', 'o')
              .replaceAll('ç', 'c');
          }

          List<CityData> getFilteredCities() {
            final cities = CityData.getTurkishCities();
            if (currentQuery.isEmpty) {
              return cities;
            }
            final normalizedQuery = normalize(currentQuery);
            return cities.where((city) {
              return normalize(city.name).contains(normalizedQuery) ||
                     normalize(city.region).contains(normalizedQuery);
            }).toList();
          }

          final filteredCities = getFilteredCities();

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Şehir ara... (81 il)',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setStateModal(() {});
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                         setStateModal(() {});
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredCities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Şehir bulunamadı',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            // Key added to force rebuild when list changes drastically
                            key: ValueKey('list_${currentQuery.length}'), 
                            controller: controller,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredCities.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index >= filteredCities.length) return const SizedBox(); // Safe guard
                              final city = filteredCities[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.location_city,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                title: Text(
                                  city.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Text(city.region),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  _selectCity(city.name);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      _searchController.clear();
      setState(() {
        _searchQuery = '';
      });
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropDetails() {
    final cropGuide = CropGuide.getCropGuides()[selectedCrop!];
    if (cropGuide == null) return const SizedBox();

    return Column(
      children: [
        _buildDetailCard('Ekim Zamanı', cropGuide.plantingSeason, Icons.calendar_today_rounded),
        _buildDetailCard('Sulama', '${cropGuide.wateringSchedule} - ${cropGuide.wateringAmount}', Icons.water_drop_rounded),
        _buildDetailCard('Hasat', cropGuide.harvestTime, Icons.agriculture_rounded),
        _buildDetailCard('Bakım', cropGuide.careTips, Icons.build_rounded),
      ],
    );
  }

  Widget _buildDetailCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowingTips() {
    if (selectedCrop == null || selectedCity == null) return const SizedBox();
    
    final tips = AIService.getGrowingTips(selectedCrop!, selectedCity!);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Büyütme İpuçları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.entries.map((entry) => _buildTipSection(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildTipSection(String title, List<String> tips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => _buildTipItem(tip)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
