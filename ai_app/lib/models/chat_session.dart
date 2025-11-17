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
    final messagesList = (json['messages'] as List<dynamic>?) ?? const [];
    final messages = messagesList.map((msg) {
      if (msg is Map<String, dynamic>) {
        return {
          'role': msg['role']?.toString() ?? '',
          'content': msg['content']?.toString() ?? '',
        };
      }
      return {
        'role': '',
        'content': '',
      };
    }).toList();
    
    final createdAtRaw = json['createdAt']?.toString();
    final updatedAtRaw = json['updatedAt']?.toString();
    
    return ChatSession(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: (json['title']?.toString() ?? 'New Chat').trim().isEmpty
          ? 'New Chat'
          : json['title'].toString(),
      createdAt: createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now(),
      updatedAt: updatedAtRaw != null ? DateTime.parse(updatedAtRaw) : DateTime.now(),
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

