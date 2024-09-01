
import 'package:flutter/cupertino.dart';

import 'chat_session.dart';

class ChatSessionManager with ChangeNotifier {
  List<ChatSession> _sessions = [];
  ChatSession? _selectedSession;

  List<ChatSession> get sessions => _sessions;
  ChatSession? get selectedSession => _selectedSession;

  void addSession(ChatSession session) {
    _sessions.add(session);
    notifyListeners();
  }

  void removeSession(String id) {
    _sessions.removeWhere((session) => session.id == id);
    notifyListeners();
  }

  void addMessageToSession(String id, String role, String content) {
    final session = _sessions.firstWhere((session) => session.id == id);
    session.messages.add({'role': role, 'content': content});
    notifyListeners();
  }

  void selectSession(ChatSession session) {
    _selectedSession = session;
    notifyListeners();
  }
}
