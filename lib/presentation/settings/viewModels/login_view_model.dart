// lib/presentation/viewmodels/login_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infrastructure/apple_sign_in_service.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:domain/entities/linkedinuserprofile.dart';






class LoginViewModel extends ChangeNotifier {
  final AuthUseCase authUseCase;
  final AppleSignInService appleSignInService;
  final GoogleSignInService googleSignInService;

  LoginViewModel({required this.authUseCase, required this.appleSignInService, required this.googleSignInService});

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  bool _isButtonEnabled = false;

  bool get isButtonEnabled => _isButtonEnabled;
  bool obscureText = true;

  String? email;
  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;
  String? _accessToken;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

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



  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    // Initialize as not signing in
    _isSigningIn = false;
    notifyListeners();

    try {
      // Initialize GoogleSignIn instance
      final GoogleSignInUser? user = kIsWeb
          ? await googleSignInService.signIn(
              clientId: GOOGLE_SIGNIN_CLIENT_ID_WEB,
              scopes: <String>['email', 'openid', 'profile'],
            )
          : await googleSignInService.signIn(
              scopes: <String>['email', 'openid', 'profile'],
            );

      print(user);

      if (user == null) {
        // User canceled the sign-in
        throw Exception('Sign-in was canceled by the user.');
      }

      // For web, sync the user immediately since ID token may not always be available
      if (kIsWeb) {
        await syncUser(user.displayName, user.email, user.photoUrl);
      } else {
        // For non-web platforms, retrieve authentication details
        final idToken = user.idToken;

        // Ensure ID token is present
        if (idToken == null) {
          throw Exception('Unable to retrieve ID token. Please try again.');
        }

        // Validate the ID token with your backend
        final bool isValid = await authUseCase.validateGoogleToken(idToken);
        if (!isValid) {
          throw Exception('Google token validation failed.');
        }
        // Sync the user data
        await syncUser(user.displayName, user.email, user.photoUrl);
      }
      // Mark signing-in as successful
      _isSigningIn = true;
    } catch (error) {
      // Handle any errors during the process
      print('Error during Google Sign-In: $error');
      _errorMessage = error.toString();
    } finally {
      // Notify listeners regardless of success or failure
      notifyListeners();
    }
  }

  // Function to handle Google Sign-Out

  Future<void> syncUser(String? displayName, String email, String? photoUrl) async {
    final accessToken = await authUseCase.syncUser(displayName, email, photoUrl);
  }

  Future<void> signInWithApple() async {
    try {
      _isSigningIn = false;
      _errorMessage = null;
      // Request credentials from Apple
      final credential = await appleSignInService.getAppleIDCredential(
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
      final String? name = credential.givenName;

      if (identityToken == null) {
        throw Exception('Identity token not available in Apple credentials');
      }
      // Validate the token with backend and retrieve email if valid
      final email = await authUseCase.validateAppleToken(identityToken);

      await syncUser(name, email, null);

      _isSigningIn = true;
      // Notify listeners for UI update
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign in with Apple failed: $e';
      _isSigningIn = false; // Reset signing in state
      notifyListeners();// Optionally rethrow for higher-level error handling
    }
  }

  // LinkedIn Credentials
  static const String clientId = '86qaow3mt03cac';
  static const String clientSecret = 'WPL_AP1.PpTXkzhjiNreIsOQ.gkbYjQ==';
  static const String redirectUrlWeb = 'http://localhost:5000/auth/linkedin/callback';
  static const String redirectUrlMobile = 'https://compositesai.com/linkedin-auth';
  static final String redirectUrl = kIsWeb ? redirectUrlWeb : redirectUrlMobile;
  static const String linkedInAuthUrl = 'https://www.linkedin.com/oauth/v2/authorization';
  static const String linkedInTokenUrl = 'https://www.linkedin.com/oauth/v2/accessToken';
  static const String linkedInUserInfoUrl = 'https://api.linkedin.com/v2/userinfo';

  Future<void> signInWithLinkedin() async {
    _isSigningIn = false;
    _errorMessage = null;
    notifyListeners();

    try {
      // **Step 1: Open LinkedIn Login Page**
      final Uri authUri = Uri.https(
        'www.linkedin.com',
        '/oauth/v2/authorization',
        {
          'response_type': 'code',
          'client_id': clientId,
          'scope': 'openid profile email',
          'state': '123456',
          'redirect_uri': redirectUrl,
        },
      );
      if (await canLaunchUrl(authUri)) {//This opens the URL in the browser (GET request happens automatically)
        await launchUrl(authUri);
      } else {
        throw Exception("Could not launch LinkedIn login page");
      }

      // **Step 2: Wait for Redirect URL with Authorization Code**
      String? authorizationCode = await _waitForAuthorizationCode();
      print(authorizationCode);

      if (authorizationCode == null) {
        throw Exception("Failed to get authorization code from LinkedIn.");
      }

      // **Step 3: Exchange Code for Access Token**
      final tokenResponse = await http.post(
        Uri.parse(linkedInTokenUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "grant_type": "authorization_code",
          "code": authorizationCode,
          "client_id": clientId,
          "client_secret": clientSecret,
          "redirect_uri": redirectUrl
        },
      );

      if (tokenResponse.statusCode == 200) {
        final data = jsonDecode(tokenResponse.body);
        _accessToken = data["access_token"];
        notifyListeners();

        // **Step 4: Fetch LinkedIn User Info**
        final LinkedinUserProfile credential = await fetchLinkedInUserProfile();
        final email = credential.email;
        final String? name = credential.name;
        final String? profile = credential.picture;

        await syncUser(name, email, profile);

        _isSigningIn = true;
        notifyListeners();

      } else {
        throw Exception("Failed to get access token: ${tokenResponse.body}");
      }
    } catch (error) {
      _errorMessage = "LinkedIn Sign-In Failed: $error";
      notifyListeners();
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  /// **2️⃣ Handle Redirect and Exchange Authorization Code for Access Token**
  Future<String?> _waitForAuthorizationCode() async {
    final completer = Completer<String?>();
    //Completer is a special object in Dart that doesn't have a value right away. just a "future value holder"

    if (kIsWeb) {
      // **For Web: Listen to the redirected URL**
      window.onMessage.listen((event) {
        print("📩 Received message from web: ${event.data}");
        if (event.data is Map && event.data.containsKey("authorizationCode")) {
          print("✅ Authorization code received: ${event.data["authorizationCode"]}");
          completer.complete(event.data["authorizationCode"]);
        }
      });
    } else {
      // **For Mobile: Listen to deep links using `uriLinkStream`**
     /* linkStream.listen((String? uri) {
        if (uri != null && uri.toString().startsWith("https://compositesai.com//auth")) {
          String? code = uri.queryParameters["code"];
          completer.complete(code);
        }
      }); */
      print("cool");
    }

    return completer.future;
  }

  /// **3️⃣ Fetch LinkedIn User Profile**
  Future<LinkedinUserProfile> fetchLinkedInUserProfile() async {
    if (_accessToken == null) {
      throw Exception("Access token is missing.");
    }

    // **Step 1: Fetch Basic Profile**
    final profileResponse = await http.get(
      Uri.parse("https://api.linkedin.com/v2/me"),
      headers: {
        "Authorization": "Bearer $_accessToken",
        "Content-Type": "application/json"
      },
    );

    // **Step 2: Fetch Email Address**
    final emailResponse = await http.get(
      Uri.parse("https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))"),
      headers: {
        "Authorization": "Bearer $_accessToken",
        "Content-Type": "application/json"
      },
    );

    if (profileResponse.statusCode == 200 && emailResponse.statusCode == 200) {
      final profileData = jsonDecode(profileResponse.body);
      final emailData = jsonDecode(emailResponse.body);

      return LinkedinUserProfile(
        email: emailData["elements"][0]["handle~"]["emailAddress"] ?? "",
        name: profileData["localizedFirstName"] + " " + profileData["localizedLastName"],
        picture: profileData["profilePicture"]?["displayImage~"]?["elements"]?.last["identifiers"]?.first["identifier"],
      );
    } else {
      throw Exception("Failed to fetch LinkedIn user profile.");
    }
  }

  /// **4️⃣ Secure Random String Generator**
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}



