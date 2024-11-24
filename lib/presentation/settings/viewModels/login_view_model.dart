// lib/presentation/viewmodels/login_view_model.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;

class LoginViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;

  LoginViewModel({required this.authUseCase});

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  bool _isButtonEnabled = false;

  bool get isButtonEnabled => _isButtonEnabled;
  bool obscureText = true;

  String? email;

  void togglePasswordVisibility() {
    obscureText = !obscureText;
    notifyListeners();
  }

  void updateButtonState(String email, String password) {
    final isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    _isButtonEnabled = isEmailValid && password.isNotEmpty && password.length >= 6;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accessToken = await authUseCase.login(email, password);
      return accessToken; // Successful login returns the access token
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static String GOOGLE_SIGNIN_CLIENT_ID_WEB = dotenv.env['GOOGLE_SIGNIN_CLIENT_ID_WEB'] ?? "";

  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    _isSigningIn = false;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn;
      if (kIsWeb) {
        googleSignIn = GoogleSignIn(
          clientId: GOOGLE_SIGNIN_CLIENT_ID_WEB,
          scopes: <String>['email', 'openid', 'profile'],
        );
        GoogleSignInAccount? _user = await googleSignIn.signIn();
        await syncUser(_user?.displayName, _user!.email, _user?.photoUrl);
        notifyListeners();
        _isSigningIn = true;
      } else {
        googleSignIn = GoogleSignIn(
          scopes: <String>['email', 'openid', 'profile'],
        );
        GoogleSignInAccount? _user = await googleSignIn.signIn();
        if (_user == null) {
          // User canceled the sign-in
          throw Exception('Sign-in was canceled by the user.');
        }
        final GoogleSignInAuthentication auth = await _user.authentication;
        if (auth.idToken == null) {
          throw Exception('Unable to retrieve ID token. Please try again.');
          // You could also notify listeners here if you want to update the UI
        }
        final bool isValid = await authUseCase.validateGoogleToken(auth.idToken!);
        if (!isValid) {
          throw Exception('Google token validation failed.');
        }
        await syncUser(_user.displayName, _user.email, _user.photoUrl);
        notifyListeners();
        _isSigningIn = true;
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
    } finally {
      notifyListeners();
    }
  }

  // Function to handle Google Sign-Out
  Future<void> signOut() async {
    final GoogleSignIn googleSignIn;
    if (kIsWeb) {
      googleSignIn = GoogleSignIn(
        clientId: GOOGLE_SIGNIN_CLIENT_ID_WEB,
        scopes: <String>['email', 'openid'],
      );
    } else {
      googleSignIn = GoogleSignIn(
        scopes: <String>['email', 'openid'],
      );
    }

    await googleSignIn.signOut();
    notifyListeners();
  }

  Future<String> syncUser(String? displayName, String email, String? photoUrl) async {
    final accessToken = await authUseCase.syncUser(displayName, email, photoUrl);
    return accessToken;
  }

  Future<void> signInWithApple() async {
    try {
      _isSigningIn = false;
      // Request credentials from Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: kIsWeb ? 'com.example.swiftcompsignin' : 'com.cdmHUB.SwiftComp',
          redirectUri: kIsWeb //This is where Apple sends the user back after they sign in.
              ? Uri.parse('https://compositesai.com')
              : Uri.parse(
                  'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
                ),
        ),
      );

      print('Apple credential: $credential');
      // Get the identity token
      final identityToken = credential.identityToken;

      if (identityToken == null) {
        throw Exception('Identity token not available in Apple credentials');
      }
      // Validate the token with backend and retrieve email if valid
      String email = await validateAppleToken(identityToken);

      await syncUser(null, email, null);

      _isSigningIn = true;
      // Notify listeners for UI update
      notifyListeners();
    } catch (e) {
      print('Sign in with Apple failed: $e');
      rethrow; // Optionally rethrow for higher-level error handling
    }
  }

  Future<String> validateAppleToken(String identityToken) async {
    return await authUseCase.validateAppleToken(identityToken);
  }
}
