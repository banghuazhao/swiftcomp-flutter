// lib/presentation/viewmodels/feature_flag_view_model.dart

import 'package:domain/use_cases/auth_use_case.dart';
import 'package:flutter/material.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/feature_flag_provider.dart';

import '../../../util/chat_limiter.dart';

class QASettingsViewModel extends ChangeNotifier {
  final FeatureFlagProvider featureFlagProvider;
  final APIEnvironment apiEnvironment;
  final AuthUseCase authUseCase;
  final ChatLimiter chatLimiter = ChatLimiter();

  String? currentEnvironment;
  int dailyChatCount = 0;
  bool isLoading = false;

  QASettingsViewModel(
      {required this.featureFlagProvider,
      required this.apiEnvironment,
      required this.authUseCase}) {
    _loadCurrentEnvironment();
    _loadDailyChatCount();
  }

  Map<String, bool> get featureFlags => featureFlagProvider.allFeatureFlags();

  bool getFeatureFlag(String key) {
    return featureFlagProvider.getFeatureFlag(key);
  }

  void toggleFeatureFlag(String key) {
    featureFlagProvider.toggleFeatureFlag(key);
    notifyListeners();
  }

  Future<void> _loadCurrentEnvironment() async {
    currentEnvironment = await apiEnvironment.getCurrentEnvironment();
    notifyListeners();
  }

  Future<void> changeEnvironment(String environment) async {
    isLoading = true;
    notifyListeners();
    try {
      await authUseCase.logout();
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await apiEnvironment.setEnvironment(environment);
      currentEnvironment = environment;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetDailyChatCount() async {
    await chatLimiter.resetDailyChatCount();
    _loadDailyChatCount();
  }

  Future<void> _loadDailyChatCount() async {
    dailyChatCount = await chatLimiter.getChatCount();
    notifyListeners();
  }
}
