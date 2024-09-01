import 'package:flutter/cupertino.dart';

class ChatSession {
  final String id;
  final String title;
  List<Map<String, String>> messages;

  // Constructor
  ChatSession({
    required this.id,
    required this.title,
    List<Map<String, String>>? messages, // Optional parameter for messages
  }) : messages = messages ?? []; // Initialize messages as an empty list if null
}