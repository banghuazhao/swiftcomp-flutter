// lib/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:swiftcomp/presentation/settings/views/qa_settings_page.dart';
import 'package:swiftcomp/presentation/settings/views/tool_creation_request.dart';
import 'package:swiftcomp/presentation/settings/views/user_profile_page.dart';
import '../../../app/injection_container.dart';
import '../../chat/viewModels/composites_tools_view_model.dart';
import '../viewModels/manage_composite_experts_view_model.dart';
import '../viewModels/settings_view_model.dart';
import 'apply_expert_page.dart';
import 'login_page.dart';
import 'manage_composite_experts_page.dart';
import 'tool_setting_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

//When Flutter builds the SettingsPage, it runs createState() to create the helper object (_SettingsPageState) that will manage the widget's state
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<SettingsViewModel>(context, listen: false);
    _fetchAuthSession();
  }

  Future<void> _fetchAuthSession() async {
    await viewModel.fetchAuthSessionNew();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      // listen to changes in SettingsViewModel
      builder: (context, viewModel, _) {
        //If every part of the widget depends on the state or changes dynamically, there’s no need to pass a child. Let the Consumer rebuild the entire widget tree.
        return Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          body: ProgressHUD(
            child: Builder(
              builder: (context) => ListView(
                children: [
                  if (!viewModel.isLoggedIn)
                    MoreRow(
                      title: "Login",
                      leadingIcon: Icons.person_rounded,
                      onTap: () async {
                        String? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                        if (result == "Log in Success") {
                          await viewModel.fetchAuthSessionNew();
                        }
                      },
                    ),
                  if (viewModel.isLoggedIn)
                    ListTile(
                      key: ValueKey(viewModel.user?.name ?? ""),
                      leading: viewModel.user?.avatarUrl != null
                          ? CircleAvatar(
                              radius: 22.5, // Adjust the radius to match the icon size
                              backgroundColor: Colors.transparent,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: viewModel.user!.avatarUrl!,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(strokeWidth: 2),
                                  errorWidget: (context, url, error) {
                                    debugPrint('Error loading image: $url, Error: $error');
                                    return const Icon(Icons.error, color: Colors.red);
                                  },
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 45,
                              color: Colors.blueGrey,
                            ),
                      title: Row(
                        children: [
                          Text(
                            viewModel.user?.name ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (viewModel.user?.isCompositeExpert ==
                              true) // Check if the user is verified
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              // Add spacing between name and icon
                              child: Icon(
                                Icons.verified, // Use a verified checkmark icon
                                color: Colors.blue, // Make it blue to represent verification
                                size: 16, // Adjust the size to fit nicely
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(viewModel.user?.email ?? ""),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(user: viewModel.user),
                          ),
                        );
                        await _fetchAuthSession();
                      },
                    ),
                  if (viewModel.isLoggedIn && viewModel.isAdmin && viewModel.user != null)
                    MoreRow(
                      leadingIcon: Icons.construction_rounded,
                      title: "Manage Expert Application",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                                create: (_) => ManageCompositeExpertsViewModel(
                                    userUseCase: sl(),
                                    compositeExpertUseCase: sl(),
                                    user: viewModel.user!),
                                child: ManageCompositeExpertsPage()),
                          ),
                        );
                      },
                    ),
                  if (viewModel.isLoggedIn && viewModel.isAdmin && viewModel.user != null)
                    MoreRow(
                      leadingIcon: Icons.add_chart_outlined,
                      title: "Manage Tool Creation Request",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                                create: (_) => CompositesToolsViewModel(
                                    toolUseCase: sl(),
                                    user: viewModel.user!,
                                  ),
                                child: ToolCreationRequestPage()),
                          ),
                        );
                      },
                    ),
                  if (viewModel.isLoggedIn && !viewModel.isExpert)
                    MoreRow(
                      leadingIcon: Icons.account_box_outlined,
                      title: "Request to Become an Expert",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyExpertPage(),
                          ),
                        );
                      },
                    ),
                  MoreRow(
                    title: "Tools Settings",
                    leadingIcon: Icons.settings_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ToolSettingPage()),
                    ),
                  ),
                  MoreRow(
                    title: "Feedback",
                    leadingIcon: Icons.chat_rounded,
                    onTap: viewModel.openFeedback,
                  ),
                  MoreRow(
                    title: "Rate this App",
                    leadingIcon: Icons.thumb_up_rounded,
                    onTap: () {
                      print("Rate App button tapped"); // Debug print
                      viewModel.rateApp();
                    },
                  ),
                  MoreRow(
                    title: "Share this App",
                    leadingIcon: Icons.share_rounded,
                    onTap: () => viewModel.shareApp(context),
                  ),
                  GestureDetector(
                    onTap: () => viewModel.handleTap(
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QASettingsPage()),
                        );
                        viewModel.fetchAuthSessionNew();
                      },
                    ),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text("Version ${viewModel.version}"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MoreRow extends StatelessWidget {
  final IconData leadingIcon;
  final IconData trailingIcon;
  final String title;
  final void Function() onTap;

  MoreRow(
      {Key? key,
      this.trailingIcon = Icons.chevron_right_rounded,
      required this.leadingIcon,
      required this.title,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Ink(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          onTap: onTap,
          child: ListTile(
            leading: Icon(leadingIcon),
            trailing: Icon(trailingIcon),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
