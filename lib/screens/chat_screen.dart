import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String listingId;
  final String otherUserId;
  final String otherUserName;
  final String? listingTitle;

  const ChatScreen({
    super.key,
    required this.listingId,
    required this.otherUserId,
    required this.otherUserName,
    this.listingTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Set active chat (prevent notifications)
    MessageService.currentChatListingId = widget.listingId;
    
    _loadMessages();
    // Realtime instead of polling for smoother experience
    _setupRealtimeSubscription();
    // Mark messages as read immediately when entering
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      await MessageService.markMessagesAsRead(
        widget.listingId, 
        widget.otherUserId,
      );
    } catch (_) {} 
  }

  @override
  void dispose() {
    // Clear active chat
    if (MessageService.currentChatListingId == widget.listingId) {
      MessageService.currentChatListingId = null;
    }
    
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.unsubscribe();
    super.dispose();
  }
  
  // Realtime Subscription
  RealtimeChannel? _messagesSubscription;

  void _setupRealtimeSubscription() {
    _messagesSubscription = Supabase.instance.client
        .channel('public:marketplace_messages:chat_${widget.listingId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'marketplace_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'listing_id',
            value: widget.listingId,
          ),
          callback: (payload) {
            final newMsg = payload.newRecord;
            // Filter out my own messages (they are added optimistically)
            if (newMsg['sender_id'] == _currentUser?.id) return;
            
            // Filter correct pair (optional double check)
            if (newMsg['sender_id'] != widget.otherUserId && newMsg['receiver_id'] != widget.otherUserId) return;

            if (mounted) {
              setState(() {
                _messages.add(newMsg);
              });
              // Smooth scroll to bottom on new message
              WidgetsBinding.instance.addPostFrameCallback((_) {
               _scrollToBottom();
               // Mark this specific new message as read since user is viewing it
               try {
                 MessageService.markAsRead(newMsg['id']);
               } catch (_) {}
            });
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    try {
      final messages = await MessageService.getMessagesForConversation(
        widget.listingId,
        widget.otherUserId,
      );
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        // Initial load: Jump to bottom immediately without animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // If close to bottom, animate. If far, jump.
      final position = _scrollController.position;
      if (position.maxScrollExtent - position.pixels < 200) {
         _scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
         // Force scroll for new messages even if user is up? 
         // Usually better to notify "New Message", but user requested "Auto scroll down"
         _scrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Optimistik UI update (hemen ekranda göster)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = {
      'id': tempId,
      'sender_id': _currentUser?.id,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
      'is_temp': true, // Mark as temporary
    };
    
    setState(() {
      _messages.add(tempMessage);
    });
    
    // Force scroll to bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      await MessageService.sendMessage(
        listingId: widget.listingId,
        receiverId: widget.otherUserId,
        message: text,
      );
      // No need to reload, realtime will handle it or we kept the temp one.
      // Actually, we should replace the temp one with real one if we want 'id' consistency, 
      // but for simple chat, keeping it is fine until next load.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId); // Hata varsa ekrandan sil
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.listingTitle != null)
              Text(
                widget.listingTitle!,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Sohbeti başlatın 👋',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == _currentUser?.id;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector( // Added Gesture Detector
        onLongPress: () => _confirmDeleteMessage(msg['id']),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg['message'] ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(msg['created_at']),
                style: TextStyle(
                  color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinize emin misiniz?'),
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
      await MessageService.deleteMessage(messageId);
      // Realtime listener should automatically handle the UI via DELETE event,
      // but 'onPostgresChanges' with 'INSERT' won't catch DELETEs unless configured.
      // So we manually remove it from the list.
      setState(() {
        _messages.removeWhere((m) => m['id'] == messageId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Mesaj yazın...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr).toLocal();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
