import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/injection_container.dart';
import '../../settings/views/login_page.dart';
import '../../settings/views/user_profile_page.dart';
import '../viewModels/chat_view_model.dart';
import 'chat_message_list.dart';
import 'chat_session_drawer.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  late ChatViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _fetchAuthSession();
  }

  Future<void> _fetchAuthSession() async {
    await viewModel.fetchAuthSessionNew();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure AutomaticKeepAliveClientMixin works
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Chat"),
            actions: [
              Builder(
                builder: (context) {
                  if (!viewModel.isLoggedIn) {
                    // If the user is not logged in, show login icon
                    return IconButton(
                      icon: const Icon(Icons.login),
                      color: Colors.white,
                      tooltip: "Sign In",
                      onPressed: () async {
                        String? result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                        if (result == "Log in Success") {
                          await viewModel.checkAuthStatus();
                          setState(() {}); // Trigger UI rebuild
                        }
                      },
                    );
                  } else {
                    // If the user is logged in, show profile info
                    return Row(
                      mainAxisSize: MainAxisSize.min, // Keep it compact
                      children: [
                        GestureDetector(
                          onTap: () async {
                            String? result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfilePage(),
                              ),
                            );
                            if (result == "refresh") {
                              await viewModel.checkAuthStatus(); // Refresh the authentication status
                              setState(() {}); // Rebuild the UI
                            }
                          },
                          child: viewModel.user?.avatarUrl != null
                              ? CircleAvatar(
                            backgroundImage: NetworkImage(viewModel.user!.avatarUrl!),
                            radius: 16, // Adjust radius to fit in the app bar
                          )
                              : const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          drawer: viewModel.isLoggedIn ? ChatDrawer() : null,
          body: viewModel.isLoggedIn
              ? ChatMessageList()
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "You need to be logged in to use the chat feature.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                    if (result == "Log in Success") {
                      await viewModel.checkAuthStatus();
                      setState(() {}); // Trigger UI rebuild
                    }
                  },
                  child: const Text("Login to Chat"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}