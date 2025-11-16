class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, String>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // Convert messages from List<dynamic> to List<Map<String, String>>
    final messagesList = json['messages'] as List<dynamic>;
    final messages = messagesList.map((msg) {
      final msgMap = msg as Map<String, dynamic>;
      return {
        'role': msgMap['role']?.toString() ?? '',
        'content': msgMap['content']?.toString() ?? '',
      };
    }).toList();
    
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: messages,
    );
  }

  String getPreviewTitle() {
    if (messages.isEmpty) return 'New Chat';
    final firstUserMessage = messages.firstWhere(
      (msg) => msg['role'] == 'user',
      orElse: () => {'content': 'New Chat'},
    );
    final content = firstUserMessage['content'] ?? 'New Chat';
    return content.length > 30 ? '${content.substring(0, 30)}...' : content;
  }
}

