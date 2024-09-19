import 'package:http/http.dart' as http;
import 'package:swiftcomp/home/Chat/chat_session.dart';
import 'dart:convert';
import 'chat_config.dart';

class ChatService {
  // ChatConfig is in .gitignore. You should use your own API key here.
  final String _apiKey = ChatConfig.apiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Stream<String> sendMessage(ChatSession chatSession) async* {
    final request = http.Request('POST', Uri.parse(_apiUrl))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      })
      ..body = jsonEncode({
        "model": "gpt-4o",
        "stream": true,  // Enable streaming
        'messages': chatSession.messages,
      });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      final utf8DecodedStream = streamedResponse.stream.transform(utf8.decoder);

      // Buffer to accumulate each word
      String buffer = '';

      await for (var chunk in utf8DecodedStream) {
        buffer += chunk;

        // Split the buffer by newlines
        List<String> lines = buffer.split('\n');

        // Retain the last line in the buffer (it may be incomplete)
        buffer = lines.removeLast();

        for (var line in lines) {
          // Only process lines starting with "data:"
          if (line.startsWith('data:')) {
            var jsonString = line.replaceFirst('data: ', '').trim();

            if (jsonString == '[DONE]') {
              // Close the stream if done
              return;
            }

            try {
              final data = jsonDecode(jsonString);

              if (data['choices'] != null && data['choices'].isNotEmpty) {
                var content = data['choices'][0]['delta']['content'] ?? '';
                // print(content);
                yield content;
              }
            } catch (e) {
              // Handle JSON parsing errors, likely due to incomplete data
              continue;
            }
          }
        }
      }

    } else {
      print(streamedResponse.statusCode);
      throw Exception('Failed to communicate with ChatGPT');
    }
  }
}
