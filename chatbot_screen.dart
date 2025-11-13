import 'package:flutter/material.dart';
import 'package:quanlytaichinh/services/gemini_service.dart';
import 'package:quanlytaichinh/services/api_key_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _apiKey;
  final ScrollController _scrollController = ScrollController();
  bool _apiConnected = false;

  // 🔑 API KEY CỐ ĐỊNH - THAY THẾ BẰNG KEY CỦA BẠN
  static const String _hardcodedApiKey =
      'AIzaSyC6mdIRQdSzkyFCDwR3STdvnCvfXn0bfnU';

  @override
  void initState() {
    super.initState();
    _initializeApiKey();
    // Thêm tin nhắn chào mừng
    _messages.add(ChatMessage(
      text:
          "Xin chào! Tôi là MoneyMate AI - trợ lý tài chính của bạn. Tôi có thể giúp gì cho bạn về quản lý tài chính, ngân sách, tiết kiệm hay đầu tư?",
      isUser: false,
    ));
  }

  Future<void> _initializeApiKey() async {
    try {
      // Ưu tiên sử dụng key cứng trước
      setState(() {
        _apiKey = _hardcodedApiKey;
        _apiConnected = true;
      });

      print('🔑 Sử dụng API Key cứng: ${_hardcodedApiKey.substring(0, 10)}...');

      // Test kết nối API
      await _testApiConnection();
    } catch (e) {
      print('❌ Lỗi khởi tạo API: $e');
      setState(() {
        _apiConnected = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    try {
      final geminiService = GeminiService(apiKey: _apiKey);
      // Test với câu hỏi đơn giản
      final testResponse = await geminiService.generateResponse("Xin chào");

      if (testResponse.isNotEmpty) {
        setState(() {
          _apiConnected = true;
        });
        print('✅ Kết nối Gemini API thành công!');
      } else {
        setState(() {
          _apiConnected = false;
        });
        print('⚠️ API trả response rỗng');
      }
    } catch (e) {
      setState(() {
        _apiConnected = false;
      });
      print('❌ Lỗi kết nối Gemini API: $e');
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Thêm tin nhắn người dùng
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Kiểm tra API key
    if (_apiKey == null || _apiKey!.isEmpty || !_apiConnected) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              "❌ Không thể kết nối đến AI. Vui lòng kiểm tra:\n\n• Kết nối internet\n• API Key có hợp lệ\n• Gemini API đã được kích hoạt",
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      // Gọi Gemini AI - API THỰC
      final geminiService = GeminiService(apiKey: _apiKey);
      final response = await geminiService.generateResponse(message);

      if (response.isEmpty) {
        throw Exception('API trả response rỗng');
      }

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ Lỗi API: $e');
      String errorMessage = "⚠️ Lỗi kết nối AI: $e";

      // Xử lý lỗi chi tiết
      if (e.toString().contains('404')) {
        errorMessage =
            "❌ Lỗi 404: Model không tìm thấy.\n\n🔄 Đang thử model khác...";
      } else if (e.toString().contains('400')) {
        errorMessage = "❌ Lỗi 400: API Key hoặc request không hợp lệ.";
      } else if (e.toString().contains('403')) {
        errorMessage = "❌ Lỗi 403: API Key không có quyền truy cập.";
      } else if (e.toString().contains('429')) {
        errorMessage = "❌ Lỗi 429: Đã vượt quá hạn mức sử dụng.";
      } else if (e.toString().contains('500')) {
        errorMessage = "❌ Lỗi 500: Lỗi server từ Google.";
      } else if (e.toString().contains('Không thể kết nối')) {
        errorMessage = "❌ Không thể kết nối đến API.\n\n💡 Gợi ý:\n"
            "• Kiểm tra kết nối internet\n"
            "• Xác nhận API Key hợp lệ\n"
            "• Đảm bảo Gemini API đã được kích hoạt";
      }

      setState(() {
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
        ));
        _isLoading = false;
        _apiConnected = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text:
            "Xin chào! Tôi là MoneyMate AI - trợ lý tài chính của bạn. Tôi có thể giúp gì cho bạn về quản lý tài chính, ngân sách, tiết kiệm hay đầu tư?",
        isUser: false,
      ));
    });
  }

  void _retryApiConnection() {
    setState(() {
      _apiConnected = true;
    });
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Advisor - MoneyMate"),
        backgroundColor: const Color(0xFF009E60),
        foregroundColor: Colors.white,
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
              tooltip: "Xóa lịch sử chat",
            ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(
                      _apiConnected ? Icons.check_circle : Icons.error,
                      color: _apiConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(_apiConnected ? '✅ API Đang hoạt động' : '❌ API Lỗi'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'retry',
                child: const Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('🔄 Thử kết nối lại'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'retry') {
                _retryApiConnection();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hiển thị trạng thái API Key
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _apiConnected ? Colors.green[50] : Colors.orange[50],
            child: Row(
              children: [
                Icon(
                  _apiConnected ? Icons.check_circle : Icons.warning,
                  color: _apiConnected ? Colors.green[700] : Colors.orange[700],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _apiConnected
                        ? "✅ Đã kết nối Gemini AI - Sẵn sàng chat!"
                        : "⚠️ Đang sử dụng chế độ Demo - API gặp sự cố",
                    style: TextStyle(
                      color: _apiConnected ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!_apiConnected)
                  TextButton(
                    onPressed: _retryApiConnection,
                    child: Text(
                      'Thử lại',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Hiển thị tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),

          // Hiển thị loading
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_apiConnected
                        ? const Color(0xFF009E60)
                        : Colors.grey[400]!),
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _apiConnected ? 'AI đang trả lời...' : 'Đang xử lý...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Input message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi về tài chính...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor:
                      _isLoading ? Colors.grey : const Color(0xFF009E60),
                  child: IconButton(
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF009E60),
              child: Icon(
                message.isUser ? Icons.person : Icons.smart_toy,
                color: Colors.white,
                size: 14,
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    message.isUser ? const Color(0xFF009E60) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.notoSans(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}
