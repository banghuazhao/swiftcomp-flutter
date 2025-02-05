import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:domain/entities/message.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:domain/repositories_abstract/thread_runs_repository.dart';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';
import 'message_delta.dart';

enum ThreadResponseEvent {
  initial,
  threadCreated,
  runCreated,
  messageCreated,
  messageDelta,
  other
}

class ThreadRunsRepositoryImpl implements ThreadRunsRepository {
  final http.Client client;

  ThreadRunsRepositoryImpl({required this.client});

  @override
  Stream<Message> createRunStream(String threadId, String assistantId) async* {
    final request = http.Request(
        'POST', Uri.parse("${ApiConstants.threadsEndpoint}/$threadId/runs"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({
        "assistant_id": assistantId,
        "stream": true,
      });

    final http.StreamedResponse streamedResponse = await client.send(request);

    if (streamedResponse.statusCode != 200 &&
        streamedResponse.statusCode != 201) {
      throw HttpException(
        'Failed to thread run. Status: ${streamedResponse.statusCode}, '
            'Response: ${await streamedResponse.stream.bytesToString()}',
        uri: request.url,
      );
    }

    final utf8DecodedStream = streamedResponse.stream.transform(utf8.decoder);
    String buffer = '';
    Message messageObj = Message(role: "assistant");

    await for (var chunk in utf8DecodedStream) {
      buffer += chunk;
      List<String> lines = buffer.split('\n');
      buffer =
          lines.removeLast(); // Keep the last line as buffer for the next chunk

      for (var line in lines) {
        if (line == '[DONE]') return;

        final jsonString = line.replaceFirst('data: ', '').trim();

        if (jsonString.isEmpty || jsonString.contains("event: ")) continue;

        if (!jsonString.contains("thread.message.delta")) {
          continue;
        }

        try {
          final data = jsonDecode(jsonString);
          final messageDelta = MessageDelta.fromJson(data);

          // Set message ID if it’s empty
          messageObj.id =
          messageObj.id.isEmpty ? messageDelta.id : messageObj.id;

          // Append new content
          if (messageDelta.delta.content.isNotEmpty) {
            messageObj.content += messageDelta.delta.content.first.text.value;
            yield messageObj;
          }
        } catch (e) {
          // Skip malformed JSON but log for debugging
          print("Error parsing JSON: $e, Data: $jsonString");
        }
      }
    }
  }

  @override
  Stream<ThreadResponse> createMessageAndRunStream(String assistantId,
      String message) async* {
    final request =
    http.Request('POST', Uri.parse("${ApiConstants.threadsEndpoint}/runs"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiConstants.apiKey}',
        'OpenAI-Beta': 'assistants=v2',
      })
      ..body = jsonEncode({
        "assistant_id": assistantId,
        "stream": true,
        "thread": {
          "messages": [
            {"role": "user", "content": message}
          ]
        }
      });

    final http.StreamedResponse streamedResponse = await client.send(request);

    if (streamedResponse.statusCode != 200 &&
        streamedResponse.statusCode != 201) {
      throw HttpException(
        'Failed to thread run. Status: ${streamedResponse.statusCode}, '
            'Response: ${await streamedResponse.stream.bytesToString()}',
        uri: request.url,
      );
    }

    var threadResponseEvent = ThreadResponseEvent.initial;
    final utf8DecodedStream = streamedResponse.stream.transform(utf8.decoder);
    String buffer = '';
    Message messageObj = Message(role: "assistant");

    await for (var chunk in utf8DecodedStream) {
      buffer += chunk;
      List<String> lines = buffer.split('\n');
      buffer =
          lines.removeLast(); // Keep the last line as buffer for the next chunk

      for (var line in lines) {
        if (line == '[DONE]') return;
        if (line.contains("event: thread.created")) {
          threadResponseEvent = ThreadResponseEvent.threadCreated;
          continue;
        } else if (line.contains("event: thread.run.created")) {
          threadResponseEvent = ThreadResponseEvent.runCreated;
          continue;
        } else if (line.contains("event: thread.message.created")) {
          threadResponseEvent = ThreadResponseEvent.messageCreated;
          continue;
        } else if (line.contains("event: thread.message.delta")) {
          threadResponseEvent = ThreadResponseEvent.messageDelta;
          continue;
        } else if (line.contains("event:")) {
          threadResponseEvent = ThreadResponseEvent.other;
          continue;
        }

        final jsonString = line.replaceFirst('data: ', '').trim();

        if (jsonString.isEmpty) continue;

        try {
          final data = jsonDecode(jsonString);

          if (threadResponseEvent == ThreadResponseEvent.messageDelta) {
            final messageDelta = MessageDelta.fromJson(data);

            // Set message ID if it’s empty
            messageObj.id =
            messageObj.id.isEmpty ? messageDelta.id : messageObj.id;

            // Append new content
            if (messageDelta.delta.content.isNotEmpty) {
              messageObj.content += messageDelta.delta.content.first.text.value;
              yield messageObj;
            }
          } else if (threadResponseEvent == ThreadResponseEvent.threadCreated) {
            final thread = Thread.fromJson(data);
            yield thread;
          }
        } catch (e) {
          // Skip malformed JSON but log for debugging
          print("Error parsing JSON: $e, Data: $jsonString");
        }
      }
    }
  }
}
