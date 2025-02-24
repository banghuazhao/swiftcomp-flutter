import 'package:domain/entities/thread_response.dart';

class ThreadFunctionTool extends ThreadResponse {
  String callId;
  String runId;
  int index;
  String name;
  String arguments;

  ThreadFunctionTool({
    required this.callId,
    required this.runId,
    required this.index,
    required this.name,
    required this.arguments,
  });

  // Optional: Add a factory constructor for creating from JSON
  factory ThreadFunctionTool.fromJson(Map<String, dynamic> json) {
    return ThreadFunctionTool(
      callId: json['callId'],
      runId: json['runId'],
      index: json['index'],
      name: json['name'],
      arguments: json['arguments'],
    );
  }

  // Optional: Add a method for converting to JSON
  Map<String, dynamic> toJson() => {
    'callId': callId,
    'index': index,
    'name': name,
    'arguments': arguments,
  };
}