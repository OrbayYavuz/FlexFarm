import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

class AIHelperScreen extends StatefulWidget {
  const AIHelperScreen({super.key});

  @override
  State<AIHelperScreen> createState() => _AIHelperScreenState();
}

class _AIHelperScreenState extends State<AIHelperScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ImagePicker _picker = ImagePicker();
  static const String _storageKey = 'ai_chat_history';

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
    
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedMessages = prefs.getString(_storageKey);
    
    if (storedMessages != null) {
      final List<dynamic> decodedList = jsonDecode(storedMessages);
      setState(() {
        _messages.clear();
        for (var item in decodedList) {
          _messages.add(Map<String, String>.from(item));
        }
      });
    } else {
      // Hoş geldin mesajı (sadece kayıtlı mesaj yoksa)
      setState(() {
        _messages.add({
          'text': '🌱 Merhaba! Ben gelişmiş bir tarım AI asistanıyım. Size şu konularda yardımcı olabilirim:\n\n• Bitki hastalığı teşhisi ve çözümleri\n• Toprak analizi ve gübreleme önerileri\n• Sulama sistemleri ve teknikleri\n• Hasat zamanı ve verim optimizasyonu\n• Organik tarım yöntemleri\n• Türkiye iklim koşullarına uygun öneriler\n\nSorularınızı sorabilir veya bitki fotoğrafı yükleyebilirsiniz!',
          'isUser': 'false',
        });
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_messages);
    await prefs.setString(_storageKey, encodedList);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': 'true',
      });
      _isLoading = true;
    });
    _saveMessages(); // Save user message immediately

    // AI yanıtı al
    final aiResponse = await AIService.getAIResponse(userMessage);

    if (mounted) {
      setState(() {
        _messages.add({
          'text': aiResponse,
          'isUser': 'false',
        });
        _isLoading = false;
      });
      _saveMessages(); // Save AI response
    }
  }
  
  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isLoading = true;
      });
      
      final Uint8List imageBytes = await image.readAsBytes();
      final aiResponse = await AIService.analyzePlantImage(imageBytes);
      
      if (mounted) {
        setState(() {
          _messages.add({
            'text': aiResponse,
            'isUser': 'false',
          });
          _isLoading = false;
        });
        _saveMessages(); // Save analysis result
      }
    }
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konuşmayı Temizle'),
          content: const Text('Tüm konuşma geçmişini silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _messages.clear();
                  AIService.clearConversationHistory();
                  // Hoş geldin mesajını tekrar ekle
                  _messages.add({
                    'text': '🌱 Merhaba! Ben gelişmiş bir tarım AI asistanıyım. Size şu konularda yardımcı olabilirim:\n\n• Bitki hastalığı teşhisi ve çözümleri\n• Toprak analizi ve gübreleme önerileri\n• Sulama sistemleri ve teknikleri\n• Hasat zamanı ve verim optimizasyonu\n• Organik tarım yöntemleri\n• Türkiye iklim koşullarına uygun öneriler\n\nSorularınızı sorabilir veya bitki fotoğrafı yükleyebilirsiniz!',
                    'isUser': 'false',
                  });
                });
                _saveMessages(); // Update storage after clearing
              },
              child: const Text('Temizle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Asistan',
                    style: AppTheme.modernTitle.copyWith(fontSize: 32),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.clear_all, color: AppTheme.textSecondary),
                          onPressed: _clearConversation,
                          tooltip: 'Konuşmayı Temizle',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                          onPressed: _showTips,
                          tooltip: 'Tarım İpuçları',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Mesaj listesi
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animation.value,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildLoadingMessage();
                        }
                        
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  );
                },
              ),
            ),
            
            // Mesaj gönderme alanı
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Added bottom padding for floating nav
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded), 
                      onPressed: _pickImage,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tarım sorunuzu yazın...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isLoading ? AppTheme.textLight : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLoading ? AppTheme.textLight : AppTheme.primaryColor).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['isUser'] == 'true';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Text(
                message['text']!,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Icon(
              Icons.smart_toy,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('AI düşünüyor...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarım İpuçları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ...AIService.getAgricultureTips().map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌱 ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(tip)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
