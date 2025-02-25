import 'dart:async';
import 'package:domain/domain.dart';
import 'package:domain/entities/thread_function_tool.dart';
import 'package:domain/entities/tool_creation_requests.dart';
import 'package:domain/entities/thread.dart';
import 'package:domain/entities/thread_response.dart';
import 'package:domain/entities/user.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/composites_tools_usecase.dart';
import 'package:domain/usecases/function_tools_usecase.dart';
import 'package:domain/usecases/functional_call_usecase.dart';
import 'package:domain/usecases/messages_usecase.dart';
import 'package:domain/usecases/thread_runs_usecase.dart';
import 'package:domain/usecases/threads_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatSessionUseCase _chatSessionUseCase;
  final AuthUseCase _authUseCase;
  final UserUseCase _userUserCase;
  final ThreadRunsUseCase _threadRunsUseCase;
  final CompositesToolsUseCase _toolsUseCase;
  final FunctionalCallUseCase _functionalCallUseCase;

  bool isLoggedIn = false;
  User? user;
  List<ToolCreationRequest> tools = [];

  final ScrollController scrollController = ScrollController();
  bool isLoading = false;

  List<ChatSession> sessions = [];
  ChatSession? _selectedSession;

  List<Message> messages = [];
  StreamController<ThreadResponse> threadResponseController =
      StreamController.broadcast();

  String? copyingMessageId;
  List<Message> selectedMessages = [];

  final assistantId = "asst_pxUDI3A9Q8afCqT9cqgUkWQP";

  List<String> defaultQuestions = [
    "What is Composites AI?",
    "What are the challenges for modeling composites?",
    "Can you tell me the early history of composites?",
    "What are common misconceptions of rules of mixtures?",
    // "Calculate laminate stress",
    // "Calculates the UDFRC properties by rules of mixture",
    // "Give me some math equations.",
  ];

  ChatViewModel({
    required ChatUseCase chatUseCase,
    required ChatSessionUseCase chatSessionUseCase,
    required FunctionToolsUseCase functionToolsUseCase,
    required AuthUseCase authUseCase,
    required UserUseCase userUserCase,
    required MessagesUseCase messagesUseCase,
    required ThreadsUseCase threadsUseCase,
    required ThreadRunsUseCase threadRunsUseCase,
    required CompositesToolsUseCase toolsUseCase,
    required FunctionalCallUseCase functionalCallUseCase,
  })  : _chatSessionUseCase = chatSessionUseCase,
        _authUseCase = authUseCase,
        _userUserCase = userUserCase,
        _threadRunsUseCase = threadRunsUseCase,
        _toolsUseCase = toolsUseCase,
        _functionalCallUseCase = functionalCallUseCase;

  Future<void> fetchAuthSessionNew() async {
    try {
      isLoggedIn = await _authUseCase.isLoggedIn();
      if (isLoggedIn) {
        await fetchUser();
      } else {
        user = null; // Ensure user is null if not logged in
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false;
      user = null; // Ensure proper reset
    }
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      user = await _userUserCase.fetchMe();
      isLoggedIn = true; // Ensure isLoggedIn is updated correctly
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      isLoggedIn = false; // Handle fetch user failure
      user = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    threadResponseController.close();
    super.dispose();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Initialize session if no sessions exist
  Future<void> initializeChatSessions() async {
    sessions = await _chatSessionUseCase.getAllSessions();
    if (sessions.isEmpty) {
      addNewSession();
    } else {
      _selectedSession = sessions.first;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    isLoggedIn = await _authUseCase.isLoggedIn();
    print("isLoggedIn: $isLoggedIn");
    if (isLoggedIn) {
      await fetchUser();
    } else {
      user = null; // Ensure user is null if not logged in
    }
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void addNewSession() {
    final newSession = _chatSessionUseCase.createNewSession();
    sessions.add(newSession);
    selectSession(newSession);
  }

  void selectSession(ChatSession session) {
    _selectedSession = session;
    messages = [..._selectedSession!.messages];
    notifyListeners();
    scrollToBottom();
  }

  Future<void> sendInputMessage(String text) async {
    final message = Message(role: 'user', content: text);
    if (_selectedSession == null) return;

    // Choose the proper stream builder based on whether we are starting a new thread.
    final Stream<ThreadResponse> Function() streamBuilder = messages.isEmpty
        ? () => _threadRunsUseCase.createThreadAndRunStream(
            assistantId, message.content)
        : () {
            final threadId = _selectedSession!.threadId!;
            return _threadRunsUseCase.createMessageAndRunStream(
                threadId, assistantId, message.content);
          };

    messages.add(message);
    setLoading(true);
    scrollToBottom();

    await _processResponseStream(streamBuilder);
  }

  Future<void> _processResponseStream(
    Stream<ThreadResponse> Function() streamBuilder,
  ) async {
    threadResponseController = StreamController<ThreadResponse>.broadcast();
    Message? finalMessage;

    try {
      final stream = streamBuilder();

      await for (final response in stream) {
        threadResponseController.add(response);

        if (response is Message) {
          finalMessage = response;
          _selectedSession?.title = response.content;
          scrollToBottom();
        } else if (response is Thread) {
          _selectedSession?.threadId = response.id;
        } else if (response is ThreadFunctionTool) {
          final threadToolOutput =
              await _functionalCallUseCase.callFunctionTool(response);
          streamBuilder() => _threadRunsUseCase.submitToolOutputsToRunStream(
              _selectedSession!.threadId!, response.runId, [threadToolOutput]);
          setLoading(true);
          scrollToBottom();
          await _processResponseStream(streamBuilder);
        }
      }
    } catch (error) {
      threadResponseController.addError(error);
      print('Error receiving messages: $error');
    } finally {
      await threadResponseController.close();
      if (finalMessage != null) {
        print(finalMessage.content);
        messages.add(finalMessage);
        saveSession();
      }
      setLoading(false);
    }
  }

  void saveSession() {
    _selectedSession?.messages = [...messages];
  }

  bool isUserMessage(Message message) {
    return message.role == 'user';
  }

  bool isAssistantMessage(Message message) {
    return message.role == 'assistant';
  }

  Future<void> onDefaultQuestionsTapped(int index) async {
    final question = defaultQuestions[index];
    await sendInputMessage(question);
  }

  Future<List<ToolCreationRequest>> getAllTools() async {
    _setLoading(true);
    try {
      // First step: Make user an expert
      tools = await _toolsUseCase.getAllTools();
      return tools;
    } catch (e) {
      tools = [];
      return tools;
    } finally {
      // Ensure the loading state is updated regardless of success or error
      _setLoading(false);
    }
  }

  void copyMessage(Message message) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    copyingMessageId = message.id;
    notifyListeners();
    Future.delayed(Duration(seconds: 1), () {
      copyingMessageId = null;
      notifyListeners();
    });
  }

  void toggleMessageSelection(Message message) {
    if (selectedMessages.contains(message)) {
      selectedMessages.remove(message);
    } else {
      selectedMessages.add(message);
    }
    notifyListeners();
  }

  bool isMessageCopying(Message message) {
    return copyingMessageId == message.id;
  }

  bool isMessageSelected(Message message) {
    return selectedMessages.contains(message);
  }

  bool? isMessageLiked(Message message) {
    return message.isLiked;
  }



  void toggleMessageLikeStatus(Message message, bool isLiked) {
    message.isLiked = isLiked;
    notifyListeners();
  }

}

// Extension on the Message class
extension ChatContentExtension on Message {
  String get chatContent {
    var contentText = content;
    if (role == 'assistant') {
      final function = toolCalls?.first.function;
      if (function != null) {
        final name = function.name;
        final arguments = function.arguments;
        contentText = contentText +
            '\n\n' +
            "Call function: $name" +
            '\n\n' +
            "Use parameters:\n\n $arguments";
      }
    }
    return contentText;
  }
}
