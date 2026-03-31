import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'listing_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await MessageService.getMyMessages();
      _processMessages(messages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesajlar yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processMessages(List<Map<String, dynamic>> messages) {
    // Mesajları konuşmalara göre grupla (Listing ID + Other User ID)
    final Map<String, Map<String, dynamic>> grouped = {};
    final currentUser = Supabase.instance.client.auth.currentUser;

    for (var msg in messages) {
      final listingId = msg['listing_id'];
      final senderId = msg['sender_id'];
      final receiverId = msg['receiver_id'];
      
      final otherUserId = senderId == currentUser?.id ? receiverId : senderId;
      final key = '${listingId}_$otherUserId';

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'listing': msg['listing'],
          'other_user': senderId == currentUser?.id ? msg['receiver'] : msg['sender'],
          'last_message': msg,
        };
      }
    }

    setState(() {
      _conversations = grouped.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Mesajlarım',
              style: AppTheme.modernTitle.copyWith(fontSize: 32),
            ),
            backgroundColor: AppTheme.backgroundColor,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_conversations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz mesajınız yok',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final conversation = _conversations[index];
                    return _buildConversationCard(conversation);
                  },
                  childCount: _conversations.length,
                ),
              ),
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
    final otherUserName = otherUser != null ? otherUser['name'] : 'Bilinmeyen Kullanıcı';
    
    // Tarih formatı (basit)
    final date = DateTime.parse(lastMessage['created_at']);
    final timeStr = '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    // Resim (logo placeholder)
    final listingImage = listing != null && listing['image_url'] != null
        ? NetworkImage(listing['image_url'])
        : const AssetImage('assets/images/logo.png') as ImageProvider;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (listing != null) {
            Navigator.push(
              context,
              PageTransitions.modernSlideTransition(
                page: ListingDetailScreen(listingId: listing['id']),
              ),
            ).then((_) => _loadMessages());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // İlan Resmi
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                  image: DecorationImage(
                    image: listingImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // İçerik
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      otherUserName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
