import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterStreamService {
  final apiKey = "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";

  Stream<String> streamResponse(String prompt, {List<Map<String, String>>? conversationHistory}) async* {
    final request = http.Request(
      "POST",
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
    );

    request.headers.addAll({
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
      "X-Title": "ChatCycleAI"
    });

    // Build messages array with conversation history
    List<Map<String, dynamic>> messages = [];
    
    // Add conversation history if provided
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      messages.addAll(conversationHistory.map((m) => {
        "role": m["role"],
        "content": m["content"]
      }));
    }
    
    // Add the current user prompt
    messages.add({"role": "user", "content": prompt});

    request.body = jsonEncode({
      "model": "openai/gpt-4.1-mini",
      "stream": true,
      "messages": messages,
      "max_tokens": 1000,
    });

    final response = await request.send();

    // Check for errors before reading the stream
    if (response.statusCode != 200) {
      // Read error message from response
      String errorMessage = 'API Error: ${response.statusCode}';
      try {
        final errorBody = await response.stream.bytesToString();
        final errorJson = jsonDecode(errorBody);
        if (errorJson['error'] != null && errorJson['error']['message'] != null) {
          errorMessage = errorJson['error']['message'] as String;
        }
      } catch (e) {
        // If we can't parse error, use default message
        if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. The API key may be invalid or expired. Please check your OpenRouter API key.';
        }
      }
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please check your API key. $errorMessage');
      }
      throw Exception(errorMessage);
    }

    await for (var chunk in response.stream.transform(utf8.decoder)) {
      for (var line in chunk.split("\n")) {
        if (line.trim().isEmpty) continue;
        
        if (line.startsWith("data: ")) {
          if (line.contains("[DONE]")) {
            break;
          }
          
          try {
            final jsonPart = jsonDecode(line.substring(6));
            if (jsonPart["choices"] != null && 
                jsonPart["choices"].isNotEmpty &&
                jsonPart["choices"][0]["delta"] != null) {
              final token = jsonPart["choices"][0]["delta"]["content"];
              if (token != null && token.toString().isNotEmpty) {
                yield token.toString();
              }
            }
          } catch (e) {
            // Skip invalid JSON lines
            continue;
          }
        }
      }
    }
  }
}