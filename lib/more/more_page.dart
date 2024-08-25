import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:launch_review/launch_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share/share.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/more/login_page.dart';
import 'package:swiftcomp/more/tool_setting_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  _MorePageState createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> with AutomaticKeepAliveClientMixin {
  bool isSignedIn = false;

  @override
  void initState() {
    super.initState();
    fetchAuthSession();
  }

  Future<void> fetchAuthSession() async {
    AuthSession authResult = await Amplify.Auth.fetchAuthSession();
    setState(() {
      isSignedIn = authResult.isSignedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("More"),
        ),
        body: ProgressHUD(
            child: Builder(
                builder: (context) => ListView(
                      children: [
                        isSignedIn
                            ? MoreRow(
                                title: "Logout",
                                leadingIcon: Icons.person_rounded,
                                onTap: () async {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context1) {
                                      return AlertDialog(
                                        title: const Text('Do you want to sign out?'),
                                        content: null,
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.pop(context1, 'Cancel'),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final progress = ProgressHUD.of(context);
                                              progress?.show();
                                              try {
                                                await Amplify.Auth.signOut();

                                                progress?.dismiss();

                                                setState(() {
                                                  isSignedIn = false;
                                                });

                                                Fluttertoast.showToast(
                                                    msg: "Logged out",
                                                    toastLength: Toast.LENGTH_SHORT,
                                                    gravity: ToastGravity.CENTER,
                                                    timeInSecForIosWeb: 2,
                                                    backgroundColor: Colors.black,
                                                    textColor: Colors.white,
                                                    fontSize: 16.0);
                                              } on AuthException catch (e) {
                                                progress?.dismiss();
                                                print(e.message);
                                              }
                                              Navigator.pop(context1, 'OK');
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                })
                            : MoreRow(
                                title: "Login",
                                leadingIcon: Icons.person_rounded,
                                onTap: () async {
                                  String received = await Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()));
                                  if (received == "Log in Success") {
                                    setState(() {
                                      isSignedIn = true;
                                    });
                                  }
                                }),
                        MoreRow(
                            title: S.of(context).Settings,
                            leadingIcon: Icons.settings_rounded,
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => const ToolSettingPage()));
                            }),
                        MoreRow(
                          title: "Feedback",
                          leadingIcon: Icons.chat_rounded,
                          onTap: () async {
                            final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

                            String device;
                            String systemVersion;
                            if (Platform.isAndroid) {
                              AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
                              device = androidInfo.model;
                              systemVersion = androidInfo.version.sdkInt.toString();
                            } else if (Platform.isIOS) {
                              IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
                              device = iosInfo.model;
                              systemVersion = iosInfo.systemVersion;
                            } else {
                              device = "";
                              systemVersion = "";
                            }

                            var packageInfo = await PackageInfo.fromPlatform();

                            String appName = packageInfo.appName;
                            String version = packageInfo.version;

                            final Uri params = Uri(
                              scheme: 'mailto',
                              path: 'appsbayarea@gmail.com',
                              query:
                                  'subject=$appName Feedback&body=\n\n\nVersion=$version\nDevice=$device\nSystem Version=$systemVersion', //add subject and body here
                            );

                            var url = params.toString();
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                        ),
                        MoreRow(
                          title: "Rate this App",
                          leadingIcon: Icons.thumb_up_rounded,
                          onTap: () {
                            LaunchReview.launch(
                                androidAppId: "com.banghuazhao.swiftcomp", iOSAppId: "1297825946");
                          },
                        ),
                        MoreRow(
                          title: "Share this App",
                          leadingIcon: Icons.share_rounded,
                          onTap: () async {
                            final Size size = MediaQuery.of(context).size;
                            var packageInfo = await PackageInfo.fromPlatform();
                            String appName = packageInfo.appName;
                            if (Platform.isIOS) {
                              Share.share("http://itunes.apple.com/app/id${"1297825946"}",
                                  subject: appName,
                                  sharePositionOrigin:
                                      Rect.fromLTRB(0, 0, size.width, size.height / 2));
                            } else {
                              Share.share(
                                  "https://play.google.com/store/apps/details?id=" +
                                      "com.banghuazhao.swiftcomp",
                                  subject: appName);
                            }
                          },
                        ),
                        if (isSignedIn)
                          MoreRow(
                            title: "Delete Current Account",
                            leadingIcon: Icons.delete_outlined,
                            onTap: () async {
                              showDialog(
                                context: context,
                                builder: (BuildContext context1) {
                                  return Expanded(
                                    child: AlertDialog(
                                      title: Text('Delete Current Account'),
                                      content: Text('Do you want to delete the current account?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context1).pop();
                                          },
                                          child: Text(
                                            'No',
                                            style: TextStyle(color: Colors.black),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context1).pop();
                                            final progress = ProgressHUD.of(context);
                                            progress?.show();
                                            try {
                                              await Amplify.Auth.deleteUser();
                                              print('Delete user succeeded');
                                              progress?.dismiss();
                                              Fluttertoast.showToast(
                                                  msg: "The account is deleted successfully",
                                                  toastLength: Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                  timeInSecForIosWeb: 2,
                                                  backgroundColor: Colors.black,
                                                  textColor: Colors.white,
                                                  fontSize: 16.0);
                                              setState(() {
                                                isSignedIn = false;
                                              });
                                            } on Exception catch (e) {
                                              progress?.dismiss();
                                              Fluttertoast.showToast(
                                                  msg: "Delete account failed",
                                                  toastLength: Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.CENTER,
                                                  timeInSecForIosWeb: 2,
                                                  backgroundColor: Colors.black,
                                                  textColor: Colors.white,
                                                  fontSize: 16.0);
                                              print('Delete user failed with error: $e');
                                            }
                                          },
                                          child: Text(
                                            'Yes',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ))));
  }

  @override
  bool get wantKeepAlive => true;
}

class MoreRow extends StatelessWidget {
  IconData leadingIcon;
  IconData trailingIcon;
  String title;
  void Function() onTap;

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
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
        ),
      ),
    );
  }
}
