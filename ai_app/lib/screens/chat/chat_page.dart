import 'package:flutter/material.dart';
import '../../services/openrouter_stream_service.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';
import '../../services/chat_storage.dart';
import '../../screens/menu/chat_menu_page.dart';
import '../../models/chat_session.dart';
import '../../core/colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final messages = <Map<String, String>>[];
  final streamService = OpenRouterStreamService();
  String? _currentSessionId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession({bool forceReload = false}) async {
    // Check if there's an initial message from home page
    final args = ModalRoute.of(context)?.settings.arguments;
    final initialMessage = args is String ? args : null;
    
    final sessionId = await ChatStorage.getCurrentSessionId();
    if (sessionId != null) {
      final session = await ChatStorage.getSession(sessionId);
      if (session != null) {
        // Always reload if session ID changed or force reload
        if (forceReload || _currentSessionId != sessionId) {
          // Different session or forced reload - load it
          setState(() {
            _currentSessionId = sessionId;
            messages.clear();
            messages.addAll(session.messages);
          });
        } else if (messages.length != session.messages.length) {
          // Same session but messages changed - reload
          setState(() {
            messages.clear();
            messages.addAll(session.messages);
          });
        }
        
        // Only send initial message if this is a new/empty session
        // If session has messages, it means we're continuing an existing chat
        if (initialMessage != null && initialMessage.isNotEmpty && session.messages.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            sendMessage(initialMessage);
          });
        }
        return;
      }
    }
    
    // Create new session if none exists
    if (_currentSessionId == null) {
      final newSession = await ChatStorage.createNewSession();
      setState(() {
        _currentSessionId = newSession.id;
        messages.clear(); // Clear any existing messages for new session
      });
      
      // If there's an initial message, send it automatically
      if (initialMessage != null && initialMessage.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sendMessage(initialMessage);
        });
      }
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSessionId == null) return;
    
    final session = await ChatStorage.getSession(_currentSessionId!);
    if (session != null) {
      final updatedSession = ChatSession(
        id: session.id,
        title: session.getPreviewTitle(),
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
        messages: messages,
      );
      await ChatStorage.saveSession(updatedSession);
    }
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Ensure we have a session
    if (_currentSessionId == null) {
      final newSession = await ChatStorage.createNewSession();
      setState(() {
        _currentSessionId = newSession.id;
      });
    }

    setState(() {
      messages.add({"role": "user", "content": text});
      messages.add({"role": "assistant", "content": ""});
    });

    await _saveCurrentSession();

    // Build conversation history for context (exclude the current empty assistant message)
    final conversationHistory = messages
        .take(messages.length - 1) // Exclude the last empty assistant message
        .where((m) => m["role"] == "user" || (m["role"] == "assistant" && m["content"]!.isNotEmpty))
        .map((m) => {"role": m["role"]!, "content": m["content"]!})
        .toList();

    try {
      await for (var token in streamService.streamResponse(text, conversationHistory: conversationHistory)) {
        if (mounted) {
          setState(() {
            messages.last["content"] =
                (messages.last["content"] ?? "") + token;
          });
        }
      }
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        setState(() {
          messages.last["content"] = "Error: ${e.toString()}";
        });
      }
      print('Stream error: $e');
    }

    await _saveCurrentSession();
  }

  @override
  Widget build(BuildContext context) {
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (ctx, i) {
                  final msg = messages[i];
                  return ChatBubble(
                    text: msg["content"]!,
                    isUser: msg["role"] == "user",
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