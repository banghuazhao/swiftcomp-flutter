import 'package:domain/entities/thread_response.dart';
import 'package:uuid/uuid.dart';

class Message extends ThreadResponse {
  String id;
  final String role;
  bool? isLiked;
  String content;
  List<ToolCalls>? toolCalls;
  String? tool_call_id;

  Message(
      {this.id = '',
      required this.role,
      this.isLiked,
      this.content = '',
      this.toolCalls,
      this.tool_call_id});

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        role = json['role'] ?? 'user',
        isLiked = json['isLiked'],
        content = json['content'] ?? '' {
    if (json['tool_calls'] != null) {
      toolCalls = <ToolCalls>[];
      json['tool_calls'].forEach((v) {
        toolCalls!.add(ToolCalls.fromJson(v));
      });
    }
    tool_call_id = json['tool_call_id'];
  }

  // Method for converting a Message instance to JSON format
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['content'] = content;
    if (toolCalls != null) {
      data['tool_calls'] = toolCalls!.map((v) => v.toJson()).toList();
    }
    data['tool_call_id'] = tool_call_id;
    return data;
  }
}

class ToolCalls {
  String? id;
  String? type;
  FunctionCall? function;

  ToolCalls({this.id, this.type, this.function});

  ToolCalls.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    function = json['function'] != null
        ? FunctionCall.fromJson(json['function'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    if (function != null) {
      data['function'] = function!.toJson();
    }
    return data;
  }
}

class FunctionCall {
  String? name;
  String? arguments;

  FunctionCall({this.name, this.arguments});

  FunctionCall.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    arguments = json['arguments'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['arguments'] = arguments;
    return data;
  }
}
