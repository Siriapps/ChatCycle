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

  Future<void> _initializeSession() async {
    // Check if there's an initial message from home page
    final args = ModalRoute.of(context)?.settings.arguments;
    final initialMessage = args is String ? args : null;
    
    final sessionId = await ChatStorage.getCurrentSessionId();
    if (sessionId != null) {
      final session = await ChatStorage.getSession(sessionId);
      if (session != null) {
        setState(() {
          _currentSessionId = sessionId;
          messages.addAll(session.messages);
        });
        
        // If there's an initial message, send it
        if (initialMessage != null && initialMessage.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            sendMessage(initialMessage);
          });
        }
        return;
      }
    }
    
    // Create new session if none exists
    final newSession = await ChatStorage.createNewSession();
    setState(() {
      _currentSessionId = newSession.id;
    });
    
    // If there's an initial message, send it
    if (initialMessage != null && initialMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sendMessage(initialMessage);
      });
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

    await for (var token in streamService.streamResponse(text)) {
      setState(() {
        messages.last["content"] =
            (messages.last["content"] ?? "") + token;
      });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.purple),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
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
}
