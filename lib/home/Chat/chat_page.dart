import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import 'chat_service.dart';
import 'chat_session.dart';
import 'chat_session_manager.dart';
import 'markdown_with_math.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Add a new session if there are no sessions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatSessionManager =
          Provider.of<ChatSessionManager>(context, listen: false);
      if (chatSessionManager.sessions.isEmpty) {
        final newSession = ChatSession(
          id: UniqueKey().toString(),
          title: 'Session 1',
        );
        chatSessionManager.addSession(newSession);
        chatSessionManager.selectSession(newSession);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      drawer: Drawer(
        child: Consumer<ChatSessionManager>(
          builder: (context, chatSessionManager, child) {
            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(51, 66, 78, 1),
                  ),
                  child: Text(
                    'Chat Sessions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ...chatSessionManager.sessions.map((session) {
                  return ListTile(
                    leading: Icon(Icons.chat),
                    title: Text(session.title),
                    onTap: () {
                      chatSessionManager
                          .selectSession(session); // Select the tapped session
                      _scrollToBottom();
                      Navigator.pop(context); // Close the drawer
                    },
                  );
                }).toList(),
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text('New Session'),
                  onTap: () {
                    final newSession = ChatSession(
                      id: UniqueKey().toString(),
                      title:
                          'Session ${chatSessionManager.sessions.length + 1}',
                    );
                    chatSessionManager.addSession(newSession);
                    chatSessionManager.selectSession(newSession);
                    Navigator.pop(context); // Close the drawer
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<ChatSessionManager>(
        builder: (context, chatSessionManager, child) {
          final session = chatSessionManager.selectedSession;

          if (session == null) {
            return Center(child: Text('No session selected.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: session.messages.length,
                  itemBuilder: (context, index) {
                    final message = session.messages[index];
                    final isUserMessage = message['role'] == 'user';

                    if (isUserMessage) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 15.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                              padding: EdgeInsets.fromLTRB(15.0, 10, 15, 10),
                              child: MarkdownWithMath(
                                  markdownData: message['content'] ?? '')));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                        ),
                      ),
                    ),
                    _isLoading
                        ? CircularProgressIndicator() // Show loading indicator
                        : IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () async {
                              if (_controller.text.isNotEmpty) {
                                setState(() {
                                  _isLoading = true; // Start loading
                                });

                                final chatService = ChatService();

                                chatSessionManager.addMessageToSession(
                                  session.id,
                                  'user',
                                  _controller.text,
                                );

                                _controller.clear();

                                _scrollToBottom();

                                // Add an empty assistant message
                                chatSessionManager.addMessageToSession(
                                  session.id,
                                  'assistant',
                                  '',
                                );

                                try {
                                  String assistantResponse = '';
                                  await chatService.sendMessage(session).listen(
                                      (word) {
                                    assistantResponse += word;
                                    chatSessionManager
                                        .updateLastAssistantMessage(
                                      session.id,
                                      assistantResponse,
                                    );
                                    _scrollToBottom(); // Scroll as words arrive
                                    // print(assistantResponse);
                                  }, onDone: () {
                                    setState(() {
                                      _isLoading = false; // Stop loading
                                    });
                                  });
                                } catch (error) {
                                  setState(() {
                                    _isLoading = false; // Stop loading
                                  });
                                }
                              }
                            },
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
