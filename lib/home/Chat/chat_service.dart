import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_config.dart';

class ChatService {
  // ChatConfig is in .gitignore. You should use your own API key here.
  final String _apiKey = ChatConfig.apiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        'messages': [
          {
            'role': 'user',
            'content': message,
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return data['choices'][0]['message']['content'].trim();
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Failed to communicate with ChatGPT');
    }
  }
}
