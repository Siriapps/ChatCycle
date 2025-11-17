import 'package:flutter/material.dart';
import '../../services/openrouter_stream_service.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';
import '../../services/chat_storage.dart';
import '../../models/chat_session.dart';
import '../../screens/menu/chat_menu_page.dart';
import '../../core/colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final streamService = OpenRouterStreamService();
  final messages = <Map<String, String>>[];
  String? _currentChatId;
  bool _isInitializing = true;
  bool _didLoadDependencies = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadDependencies) {
      _didLoadDependencies = true;
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isInitializing = true;
    });
    // Check if there's an initial message from home page
    final args = ModalRoute.of(context)?.settings.arguments;
    final initialMessage = args is String ? args : null;
    
    String? chatId = await ChatStorage.getCurrentSessionId();
    ChatSession? session;

    if (chatId != null) {
      session = await ChatStorage.getSession(chatId);
    }

    if (session == null) {
      final newSession = await ChatStorage.createNewSession();
      chatId = newSession.id;
      session = newSession;
    }

    setState(() {
      _currentChatId = chatId;
      messages
        ..clear()
        ..addAll(session!.messages);
      _isInitializing = false;
    });

    // If there's an initial message, send it to AI
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      final message = initialMessage.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sendMessage(message);
      });
    }
  }

  Future<void> _deleteCurrentChat() async {
    if (_currentChatId == null) return;
    await ChatStorage.deleteSession(_currentChatId!);
    await ChatStorage.setCurrentSessionId(null);
    setState(() {
      _currentChatId = null;
      messages.clear();
      _isInitializing = true;
    });
    _initializeChat();
  }

  Future<void> _confirmDeleteCurrentChat() async {
    if (_currentChatId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text('This will remove the chat history from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteCurrentChat();
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentChatId == null) return;
    final session = await ChatStorage.getSession(_currentChatId!);
    if (session == null) return;

    final updatedSession = ChatSession(
      id: session.id,
      title: session.getPreviewTitle(),
      createdAt: session.createdAt,
      updatedAt: DateTime.now(),
      messages: List<Map<String, String>>.from(messages),
    );
    await ChatStorage.saveSession(updatedSession);
  }

  Future<void> _sendToAI(String userMessage) async {
    if (_currentChatId == null) return;

    // Build conversation history using saved messages
    final conversationHistory = messages
        .where((m) =>
            m['role'] == 'user' ||
            (m['role'] == 'assistant' && (m['content'] ?? '').isNotEmpty))
        .map((m) => {
          'role': m['role']!,
          'content': m['content']!,
        })
        .toList();

    // Create empty assistant message for streaming
    setState(() {
      messages.add({'role': 'assistant', 'content': ''});
    });

    try {
      String accumulatedContent = '';
      await for (var token in streamService.streamResponse(userMessage, conversationHistory: conversationHistory)) {
        if (mounted && _currentChatId != null) {
          accumulatedContent += token;
          setState(() {
            messages.last['content'] = accumulatedContent;
          });
        }
      }
    } catch (e) {
      if (mounted && _currentChatId != null) {
          setState(() {
            messages.last['content'] = "Error: ${e.toString()}";
          });
      }
      print('Stream error: $e');
    } finally {
      await _saveCurrentSession();
    }
  }

  Future<void> sendMessage(String text, {String? fileUrl}) async {
    if (text.trim().isEmpty && fileUrl == null) return;

    if (_currentChatId == null || _isInitializing) return;

    setState(() {
      messages.add({'role': 'user', 'content': text});
    });
    await _saveCurrentSession();

    // Send to AI if there's text content
    if (text.trim().isNotEmpty) {
      await _sendToAI(text);
    } else {
      await _saveCurrentSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChatId == null || _isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,

      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.80,
        child: const ChatMenuPage(),
      ),

      drawerEdgeDragWidth: MediaQuery.of(context).size.width,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/icon.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'ChatCycle',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.purple, size: 24),
            onPressed: _confirmDeleteCurrentChat,
            tooltip: 'Delete chat',
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.purple, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: _navBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Start a conversation!',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        return ChatBubble(
                          text: msg['content'] ?? '',
                          isUser: msg['role'] == 'user',
                        );
                      },
                    ),
            ),
            ChatInput(onSend: sendMessage),
          ],
        ),
      ),
    );
  }

  Widget _navBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.grey,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
        BottomNavigationBarItem(
          icon: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple,
                  AppColors.purple.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Purple half circle background
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 50,
                    height: 25,
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
                // Plus icon
                const Icon(Icons.add, color: Colors.white, size: 24),
              ],
            ),
          ),
          label: "Create",
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.book), label: "Library"),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
