import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:infrastructure/in_app_reviewer_helper.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/app_colors.dart';
import 'package:swiftcomp/util/others.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'app/bottom_navigator.dart';
import 'app/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  Future.delayed(Duration(seconds: 1), () {
    AppTrackingTransparency.requestTrackingAuthorization();
  });

  InAppReviewHelper.checkAndAskForReview();

  await SharedPreferencesHelper.init();

  initInjection();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => NumberPrecisionHelper()),
          ChangeNotifierProvider(
              create: (context) => sl<FeatureFlagProvider>()),
          ChangeNotifierProvider(create: (context) => sl<SettingsViewModel>()),
          ChangeNotifierProvider(create: (context) => sl<ChatViewModel>()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // 讲en设置为第一项,没有适配语言时,英语为首选项
          supportedLocales: S.delegate.supportedLocales,
          // 插件目前不完善手动处理简繁体
          localeResolutionCallback: (locale, supportLocales) {
            print(locale);
            // 中文 简繁体处理
            if (locale?.languageCode == 'zh') {
              if (locale?.scriptCode == 'Hant') {
                return const Locale('zh', 'HK'); //繁体
              } else {
                return const Locale('zh', ''); //简体
              }
            }
            return Locale('en', '');
          },
          title: 'Composites AI',
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              onSecondary: Colors.white,
            ),
            appBarTheme: AppBarTheme(
                color: AppColors.primary,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20)),
            scaffoldBackgroundColor: AppColors.background,
            textTheme: const TextTheme(),
          ),
          home: const BottomNavigator(),
        ));
  }
}
