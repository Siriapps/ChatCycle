import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterStreamService {
  final apiKey = "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";

  Stream<String> streamResponse(String prompt) async* {
    final request = http.Request(
      "POST",
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
    );

    request.headers.addAll({
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
      "X-Title": "ChatCycleAI"
    });

    request.body = jsonEncode({
      "model": "openai/gpt-4.1-mini",
      "stream": true,
      "messages": [
        {"role": "user", "content": prompt}
      ]
    });

    final response = await request.send();

    await for (var chunk in response.stream.transform(utf8.decoder)) {
      for (var line in chunk.split("\n")) {
        if (line.startsWith("data: ") && !line.contains("[DONE]")) {
          final jsonPart = jsonDecode(line.substring(6));
          final token = jsonPart["choices"][0]["delta"]["content"];
          if (token != null) yield token;
        }
      }
    }
  }
}
