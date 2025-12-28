import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/message_service.dart';
import '../services/marketplace_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'listing_detail_screen.dart';
import 'chat_screen.dart';
import 'create_listing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final _currentUser = Supabase.instance.client.auth.currentUser;

  // Messages State
  bool _isLoadingMessages = true;
  List<Map<String, dynamic>> _conversations = [];

  // Listings State
  List<Map<String, dynamic>> _myListings = [];
  bool _isLoadingListings = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
    _loadMyListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Messages Logic ---
  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoadingMessages = true);
    try {
      final messages = await MessageService.getMyMessages();
      _processMessages(messages);
    } catch (e) {
      if (mounted) {
        /* ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesajlar yüklenemedi: $e')),
        ); */
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _processMessages(List<Map<String, dynamic>> messages) {
    if (_currentUser == null) return;
    
    final Map<String, Map<String, dynamic>> grouped = {};

    for (var msg in messages) {
      final listingId = msg['listing_id'];
      final senderId = msg['sender_id'];
      final receiverId = msg['receiver_id'];
      
      final otherUserId = senderId == _currentUser!.id ? receiverId : senderId;
      final key = '${listingId}_$otherUserId';

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'listing': msg['listing'],
          'other_user': senderId == _currentUser!.id ? msg['receiver'] : msg['sender'],
          'last_message': msg,
          'unread_count': 0,
        };
      }
      
      if (receiverId == _currentUser!.id && msg['is_read'] == false) {
        grouped[key]!['unread_count'] = (grouped[key]!['unread_count'] as int) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _conversations = grouped.values.toList();
      });
    }
  }

  // --- Listings Logic ---
  Future<void> _loadMyListings() async {
    if (!mounted) return;
    setState(() => _isLoadingListings = true);

    try {
      final listings = await MarketplaceService.getMyListings();
      if (mounted) {
        setState(() {
          _myListings = listings;
          _isLoadingListings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingListings = false);
      }
    }
  }

  Future<void> _deleteListing(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlanı Sil'),
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

    if (confirmed != true) return;

    try {
      await MarketplaceService.deleteListing(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan silindi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMyListings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlan silinemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Uygulamadan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseAuthService.signOut();
              } catch (e) {
               // ignore
              }
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                'Profilim',
                style: AppTheme.modernTitle.copyWith(fontSize: 32),
              ),
              backgroundColor: AppTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 280,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  margin: const EdgeInsets.only(top: 80, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentUser?.email ?? 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    await NotificationService.showInstantNotification(
                      id: 999,
                      title: 'Test Bildirimi 🔔',
                      body: 'Bu bir test bildirimidir. Bildirimler çalışıyor!',
                      payload: 'test_payload',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test bildirimi gönderildi')),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                  tooltip: 'Bildirim Testi',
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  tooltip: 'Çıkış Yap',
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: 'Mesajlarım'),
                  Tab(text: 'İlanlarım'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Mesajlar
            _buildMessagesTab(),
            // Tab 2: İlanlarım
            _buildListingsTab(),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Messages UI ---
  Widget _buildMessagesTab() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    } else if (_conversations.isEmpty) {
      return _buildEmptyState('Henüz mesajınız yok', Icons.chat_bubble_outline);
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) => _buildConversationCard(_conversations[index]),
      );
    }
  }

  // --- Tab 2: Listings UI ---
  Widget _buildListingsTab() {
     if (_isLoadingListings) {
      return const Center(child: CircularProgressIndicator());
    } else if (_myListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz ilanınız yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
             ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransitions.modernSlideTransition(
                      page: const CreateListingScreen(),
                    ),
                  ).then((_) {
                    _loadMyListings();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('İlan Oluştur'),
              ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myListings.length,
        itemBuilder: (context, index) => _buildListingCard(_myListings[index]),
      );
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final listing = conversation['listing'];
    final otherUser = conversation['other_user'];
    final lastMessage = conversation['last_message'];
    final listingTitle = listing != null ? listing['title'] : 'Silinmiş İlan';
    
    String otherUserName = 'Bilinmeyen Kullanıcı';
    if (otherUser != null && otherUser['name'] != null) {
      final fullName = otherUser['name'] as String;
      final parts = fullName.trim().split(' ');
      if (parts.length > 1) {
        otherUserName = '${parts[0]} ${parts.last[0].toUpperCase()}.';
      } else {
        otherUserName = fullName;
      }
    }
    
    final date = DateTime.parse(lastMessage['created_at']);
    final timeStr = '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    final listingImage = listing != null && listing['image_url'] != null
        ? NetworkImage(listing['image_url'])
        : const AssetImage('assets/images/logo.png') as ImageProvider;

    final unreadCount = conversation['unread_count'] as int? ?? 0;
    final isMe = lastMessage['sender_id'] == _currentUser?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: unreadCount > 0 
              ? AppTheme.primaryColor.withValues(alpha: 0.5) 
              : Colors.grey.withValues(alpha: 0.1),
          width: unreadCount > 0 ? 1.5 : 1,
        ),
      ),
      color: unreadCount > 0 ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (listing != null && otherUser != null) {
            Navigator.push(
              context,
              PageTransitions.modernSlideTransition(
                page: ChatScreen(
                  listingId: listing['id'],
                  otherUserId: otherUser['id'],
                  otherUserName: otherUserName,
                  listingTitle: listingTitle,
                ),
              ),
            ).then((_) {
              _loadMessages();
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                   Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                      image: DecorationImage(
                        image: listingImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listingTitle,
                            style: TextStyle(
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                              color: unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textPrimary.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: unreadCount > 0 ? AppTheme.primaryColor : Colors.grey[500],
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      otherUserName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          if (isMe)
                            TextSpan(
                              text: 'Sen: ',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'GoogleFonts.inter().fontFamily',
                              ),
                            ),
                          TextSpan(
                            text: lastMessage['message'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isMe 
                                  ? AppTheme.primaryColor.withValues(alpha: 0.8)
                                  : (unreadCount > 0 ? Colors.black : Colors.grey[600]),
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'GoogleFonts.inter().fontFamily',
                            ),
                          ),
                        ],
                      ),
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

  // Reuse the card design from MyListingsScreen but slightly adapted
  Widget _buildListingCard(Map<String, dynamic> listing) {
    final price = listing['price'] as num?;
    final category = listing['category'] as String? ?? 'Diğer';
    final isAvailable = listing['is_available'] as bool? ?? true;
    final imageUrl = listing['image_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
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
            _loadMyListings();
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          memCacheHeight: 360,
                          placeholder: (context, url) => Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[50],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[100],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 120,
                          width: 120,
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          child: Center(
                            child: Opacity(
                              opacity: 0.5,
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ),
                        ),
                ),
                
                // Durum badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.withValues(alpha: 0.9) : Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAvailable ? 'Aktif' : 'Satıldı',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Kategori Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing['title'] as String? ?? 'Başlıksız',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (listing['city'] != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, 
                                    size: 16, 
                                    color: Colors.grey[500]
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    listing['city'] as String,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        price != null
                            ? '${price.toStringAsFixed(0)} ₺'
                            : '-',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Alt aksiyonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteListing(listing['id'] as String),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text('Sil'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}
