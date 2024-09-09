import 'package:http/http.dart' as http;
import 'package:swiftcomp/home/Chat/chat_session.dart';
import 'dart:convert';
import 'chat_config.dart';

class ChatService {
  // ChatConfig is in .gitignore. You should use your own API key here.
  final String _apiKey = ChatConfig.apiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessage(ChatSession chatSession) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        'messages': chatSession.messages
      }),
    );

    if (response.statusCode == 200) {
      print(response.body);
      final utf8DecodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(utf8DecodedBody);
      final message = data['choices'][0]['message']['content'];
      print(message);
      return message;
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Failed to communicate with ChatGPT');
    }
  }
}
