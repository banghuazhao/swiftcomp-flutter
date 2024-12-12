import 'package:cached_network_image/cached_network_image.dart';
import 'package:domain/entities/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/settings/views/update_name_page.dart';
import 'package:swiftcomp/presentation/settings/views/update_password.dart';
import '../../../app/injection_container.dart';
import '../viewModels/user_profile_view_model.dart';

class UserProfilePage extends StatelessWidget {
  User? user;

  UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(//Creates the UserProfileViewModel object. 2.Makes it available to the page and any widgets below it in the widget tree.
      create: (_) => UserProfileViewModel(authUseCase: sl(), userUseCase: sl(), user: user),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("User Profile"),
          backgroundColor: Color(0xFF33424E),
          elevation: 4.0,
        ),
        body: Consumer<UserProfileViewModel>(//The page accesses the ViewModel through a Consumer
          builder: (context, viewModel, _) {
            return viewModel.isLoading
                ? Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width, // 50% of the screen width
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              viewModel.user?.avatarUrl != null
                                  ? CircleAvatar(
                                radius: 27.5, // Adjust the radius to match the icon size
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: viewModel.user!.avatarUrl!,
                                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
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
                                size: 55,
                                color: Colors.blueGrey,
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel.user?.name ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    viewModel.user?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueGrey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateNamePage(
                            currentName: viewModel.user?.name ?? "",
                          ),
                        ),
                      );
                      if (result == 'refresh') {
                        await viewModel.fetchUser();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Change Name",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdatePasswordPage(),
                        ),
                      );
                      if (result == 'refresh') {
                        await viewModel.fetchUser();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Update Password",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () async {
                      await viewModel.logoutUser(context);
                      Navigator.of(context).pop("refresh");
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Logout",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _confirmDeleteUser(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.5, 50),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Delete Account",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  void _confirmDeleteUser(BuildContext context, UserProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog first

                await viewModel.deleteUser();

                if (!context.mounted) return; // Exit if widget is unmounted

                if (viewModel.errorMessage != null) {
                  // Show error dialog if an error occurred
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Error"),
                      content: Text(viewModel.errorMessage!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Navigate back with "refresh" if no error
                  Navigator.of(context).pop("refresh");
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
