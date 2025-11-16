import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class ChatStorage {
  static const sessionsKey = "chat_sessions";
  static const currentSessionKey = "current_session_id";

  // Save all chat sessions
  static Future<void> saveSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = sessions.map((s) => s.toJson()).toList();
    prefs.setString(sessionsKey, jsonEncode(sessionsJson));
  }

  // Load all chat sessions
  static Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(sessionsKey);

    if (jsonStr == null) return [];
    
    final List<dynamic> sessionsList = jsonDecode(jsonStr);
    return sessionsList.map((json) => ChatSession.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Save a single session (add or update)
  static Future<void> saveSession(ChatSession session) async {
    final sessions = await loadSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    
    await saveSessions(sessions);
  }

  // Get a session by ID
  static Future<ChatSession?> getSession(String id) async {
    final sessions = await loadSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // Delete a session
  static Future<void> deleteSession(String id) async {
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == id);
    await saveSessions(sessions);
  }

  // Get current session ID
  static Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentSessionKey);
  }

  // Set current session ID
  static Future<void> setCurrentSessionId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(currentSessionKey);
    } else {
      await prefs.setString(currentSessionKey, id);
    }
  }

  // Create a new session
  static Future<ChatSession> createNewSession() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final session = ChatSession(
      id: id,
      title: 'New Chat',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    await saveSession(session);
    await setCurrentSessionId(id);
    return session;
  }

  // Legacy support - for backward compatibility
  static Future<void> saveMessages(List<Map<String, String>> messages) async {
    final currentId = await getCurrentSessionId();
    if (currentId != null) {
      final session = await getSession(currentId);
      if (session != null) {
        final updatedSession = ChatSession(
          id: session.id,
          title: session.getPreviewTitle(),
          createdAt: session.createdAt,
          updatedAt: DateTime.now(),
          messages: messages,
        );
        await saveSession(updatedSession);
        return;
      }
    }
    
    // If no current session, create one
    final newSession = await createNewSession();
    final updatedSession = ChatSession(
      id: newSession.id,
      title: newSession.getPreviewTitle(),
      createdAt: newSession.createdAt,
      updatedAt: DateTime.now(),
      messages: messages,
    );
    await saveSession(updatedSession);
  }

  static Future<List<Map<String, String>>> loadMessages() async {
    final currentId = await getCurrentSessionId();
    if (currentId != null) {
      final session = await getSession(currentId);
      if (session != null) {
        return session.messages;
      }
    }
    return [];
  }
}
