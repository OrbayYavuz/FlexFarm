import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/marketplace_service.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';
import 'create_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'my_listings_screen.dart';
import 'messages_screen.dart'; // Added import
import '../utils/page_transitions.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  bool get wantKeepAlive => true;
  
  // Filtreleme
  String? _selectedCategory;
  String? _selectedCity;
  final TextEditingController _searchController = TextEditingController();
  
  // Pagination
  int _offset = 0;
  static const int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadListings();
    _checkUnreadMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offset = 0;
        _listings = [];
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = _offset == 0;
      _isLoadingMore = _offset > 0;
      _error = null;
    });

    try {
      final listings = await MarketplaceService.getAllListings(
        category: _selectedCategory,
        city: _selectedCity,
        searchQuery: _searchController.text.isEmpty 
            ? null 
            : _searchController.text,
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        if (refresh) {
          _listings = listings;
        } else {
          _listings.addAll(listings);
        }
        _hasMore = listings.length == _limit;
        _offset = _listings.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = 'İlanlar yüklenemedi: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _checkUnreadMessages() async {
    try {
      final count = await MessageService.getUnreadMessageCount();
      if (mounted && count > 0) {
        // Badge gösterilebilir
      }
    } catch (e) {
      // Sessizce hata yok say
    }
  }

  void _applyFilters() {
    _loadListings(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedCity = null;
      _searchController.clear();
    });
    _loadListings(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive için gerekli
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _loadListings(refresh: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(
                'Pazar Yeri',
                style: AppTheme.modernTitle.copyWith(fontSize: 32),
              ),
              centerTitle: false,
              backgroundColor: AppTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              floating: true,
              expandedHeight: 0, // Minimize extra space, just a clean sticky header
              automaticallyImplyLeading: false, // Hide back button if it appears
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
                    icon: const Icon(Icons.favorite_border, color: AppTheme.textPrimary),
                    onPressed: _navigateToMyListings,
                    tooltip: 'İlanlarım',
                  ),
                ),
                // Mesajlarım Butonu
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
                    icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.textPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransitions.modernSlideTransition(
                          page: const MessagesScreen(),
                        ),
                      );
                    },
                    tooltip: 'Mesajlarım',
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0), // Slight top spacing for search
                child: _buildSearchAndFilters(),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorWidget(),
              )
            else if (_listings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyWidget(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), // Bottom padding for FAB and Nav
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _listings.length) {
                        if (!_hasMore) return const SizedBox.shrink();
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _isLoadingMore
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: () => _loadListings(),
                                    child: const Text('Daha Fazla Yükle'),
                                  ),
                          ),
                        );
                      }
                      return _buildListingCard(_listings[index]);
                    },
                    childCount: _listings.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              PageTransitions.modernSlideTransition(
                page: const CreateListingScreen(),
              ),
            ).then((_) {
              _loadListings(refresh: true);
            });
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const StadiumBorder(),
          icon: const Icon(Icons.add),
          label: const Text('İlan Ver', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // İlanlarım sayfasına git
  void _navigateToMyListings() {
    Navigator.push(
      context,
      PageTransitions.modernSlideTransition(
        page: const MyListingsScreen(),
      ),
    ).then((_) {
      _loadListings(refresh: true);
    });
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Arama kutusu
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'İlan ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          
          // Filtreler
          Row(
            children: [
              // Kategori filtresi
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tümü'),
                    ),
                    ...MarketplaceService.getCategories().map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Şehir filtresi (basit input)
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Şehir',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value.isEmpty ? null : value;
                    });
                  },
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Temizle butonu
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _clearFilters,
                tooltip: 'Filtreleri Temizle',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingsList() {
    return RefreshIndicator(
      onRefresh: () => _loadListings(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _listings.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _listings.length) {
            // Load more indicator
            if (_isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return Center(
              child: TextButton(
                onPressed: () => _loadListings(),
                child: const Text('Daha Fazla Yükle'),
              ),
            );
          }

          final listing = _listings[index];
          return _buildListingCard(listing);
        },
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final price = listing['price'] as num?;
    final category = listing['category'] as String? ?? 'Diğer';
    final city = listing['city'] as String?;
    final imageUrl = listing['image_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.modernSlideTransition(
                page: ListingDetailScreen(
                  listingId: listing['id'] as String,
                ),
              ),
            ).then((_) {
              _loadListings(refresh: true);
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resim Alanı
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheHeight: 660, // 220 * 3 for sharper images on high density screens but optimized memory
                            placeholder: (context, url) => Container(
                              height: 220,
                              color: Colors.grey[50], 
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 220,
                              color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              child: Center(
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 80,
                                    height: 80,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: 220,
                            color: AppTheme.primaryColor.withValues(alpha: 0.05),
                            child: Center(
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (Supabase.instance.client.auth.currentUser?.email == 'orbay1907@gmail.com')
                         Padding(
                           padding: const EdgeInsets.only(left: 8),
                           child: GestureDetector(
                             onTap: () async {
                               final confirmed = await showDialog<bool>(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   title: const Text('Admin Silme'),
                                   content: const Text('Bu ilanı silmek istediğinize emin misiniz?'),
                                   actions: [
                                     TextButton(
                                       onPressed: () => Navigator.pop(context, false),
                                       child: const Text('İptal'),
                                     ),
                                     TextButton(
                                       onPressed: () => Navigator.pop(context, true),
                                       style: TextButton.styleFrom(foregroundColor: Colors.red),
                                       child: const Text('Sil'),
                                     ),
                                   ],
                                 ),
                               );
                               if (confirmed == true) {
                                 try {
                                   await MarketplaceService.deleteListing(listing['id']);
                                   _loadListings(refresh: true);
                                   if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('İlan silindi'), backgroundColor: Colors.green),
                                      );
                                   }
                                 } catch(e) {
                                   if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                                      );
                                   }
                                 }
                               }
                             },
                             child: Container(
                               padding: const EdgeInsets.all(6),
                               decoration: BoxDecoration(
                                 color: Colors.red.withValues(alpha: 0.9),
                                 shape: BoxShape.circle,
                                 border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                               ),
                               child: const Icon(Icons.delete, color: Colors.white, size: 16),
                             ),
                           ),
                         ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing['title'] as String? ?? 'Başlıksız',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          price != null ? '${price.toStringAsFixed(0)} ₺' : '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (city != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Bir hata oluştu',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadListings(refresh: true),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Henüz ilan yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk ilanı sen oluştur!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
