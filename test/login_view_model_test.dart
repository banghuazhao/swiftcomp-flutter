import 'package:domain/mocks/auth_usecase_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:mockito/mockito.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:swiftcomp/presentation/settings/viewModels/login_view_model.dart';

void main() {
  group('LoginViewModel Tests', () {
    late MockAuthUseCase mockAuthUseCase;
    late MockAppleSignInService mockAppleSignInService;
    late LoginViewModel loginViewModel;

    setUp(() {
      // Initialize the mocks and view model before each test
      mockAuthUseCase = MockAuthUseCase();
      mockAppleSignInService = MockAppleSignInService();
      loginViewModel = LoginViewModel(
        authUseCase: mockAuthUseCase,
        appleSignInService: mockAppleSignInService,
      );
    });

    tearDown(() {
      // Clean up resources or reset mock state after each test
      reset(mockAuthUseCase);
      reset(mockAppleSignInService);
    });

    group('togglePasswordVisibility', () {
      test('should toggle obscureText and notify listeners', () {
        // Initially true
        expect(loginViewModel.obscureText, true);

        // Toggle
        loginViewModel.togglePasswordVisibility();
        expect(loginViewModel.obscureText, false);

        // Toggle back
        loginViewModel.togglePasswordVisibility();
        expect(loginViewModel.obscureText, true);
      });
    });

    group('updateButtonState', () {
      test('should enable button when email and password are valid', () {
        loginViewModel.updateButtonState('test@example.com', 'password123');
        expect(loginViewModel.isButtonEnabled, true);
      });

      test('should disable button when email is invalid', () {
        loginViewModel.updateButtonState('invalid-email', 'password123');
        expect(loginViewModel.isButtonEnabled, false);
      });

      test('should disable button when password is empty', () {
        loginViewModel.updateButtonState('test@example.com', '');
        expect(loginViewModel.isButtonEnabled, false);
      });

      test('should disable button when password length is less than 6', () {
        loginViewModel.updateButtonState('test@example.com', '12345');
        expect(loginViewModel.isButtonEnabled, false);
      });
    });

    group('login', () {
      test('should set isLoading to true during login process', () async {
        const email = 'test@example.com';
        const password = 'password123';
        when(mockAuthUseCase.login(email, password)).thenAnswer((_) async => 'accessToken');

        final future = loginViewModel.login(email, password);

        expect(loginViewModel.isLoading, true);
        await future;
        expect(loginViewModel.isLoading, false);
      });

      test('should return access token on successful login', () async {
        const email = 'test@example.com';
        const password = 'password123';
        const accessToken = 'accessToken';
        when(mockAuthUseCase.login(email, password)).thenAnswer((_) async => accessToken);

        final result = await loginViewModel.login(email, password);
        expect(result, accessToken);
        expect(loginViewModel.errorMessage, null);
      });

      test('should set error message on login failure', () async {
        const email = 'test@example.com';
        const password = 'password123';
        when(mockAuthUseCase.login(email, password)).thenThrow(Exception('Login error'));

        final result = await loginViewModel.login(email, password);
        expect(result, null);
        expect(loginViewModel.errorMessage, 'Login failed: Exception: Login error');
      });
    });

    group('validateGoogleToken', () {
      test('should return true when token validation is successful', () async {
        const idToken = "1234567";

        when(mockAuthUseCase.validateGoogleToken(idToken)).thenAnswer((_) async => true);

        final result = await mockAuthUseCase.validateGoogleToken(idToken);

        expect(result, true);
        verify(mockAuthUseCase.validateGoogleToken(idToken)).called(1);
      });

      test('should return false when token validation fails', () async {
        const idToken = "1234567";

        when(mockAuthUseCase.validateGoogleToken(idToken)).thenAnswer((_) async => false);

        final result = await mockAuthUseCase.validateGoogleToken(idToken);

        expect(result, false);
        verify(mockAuthUseCase.validateGoogleToken(idToken)).called(1);
      });

      test('should throw an exception on error during token validation', () async {
        const idToken = "1234567";

        when(mockAuthUseCase.validateGoogleToken(idToken)).thenThrow(Exception('Validation error'));

        expect(
          () async => await mockAuthUseCase.validateGoogleToken(idToken),
          throwsA(isA<Exception>()),
        );
        verify(mockAuthUseCase.validateGoogleToken(idToken)).called(1);
      });
    });

    group('validateAppleToken', () {
      test('should return email when validation is successful', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();

        const identityToken = 'validIdentityToken';
        const expectedEmail = 'test@example.com';

        // Mocking the repository behavior
        when(mockAuthUseCase.validateAppleToken(identityToken))
            .thenAnswer((_) async => expectedEmail);

        final result = await mockAuthUseCase.validateAppleToken(identityToken);

        expect(result, expectedEmail);
        verify(mockAuthUseCase.validateAppleToken(identityToken)).called(1);
      });

      test('should throw an exception when validation fails', () async {
        final MockAuthUseCase mockAuthUseCase = MockAuthUseCase();
        const identityToken = 'invalidIdentityToken';

        // Mocking the repository behavior to throw an exception
        when(mockAuthUseCase.validateAppleToken(identityToken))
            .thenThrow(Exception('Validation failed'));

        expect(
          () async => await mockAuthUseCase.validateAppleToken(identityToken),
          throwsA(isA<Exception>()),
        );

        verify(mockAuthUseCase.validateAppleToken(identityToken)).called(1);
      });
    });

    group('signInWithApple', () {
      test('should sign in with Apple and update the user state on success', () async {
        // Arrange
        final mockCredential = AuthorizationCredentialAppleID(
          userIdentifier: 'mock-user-id',
          givenName: 'Mock',
          familyName: 'User',
          email: 'mockuser@example.com',
          authorizationCode: 'mock-auth-code',
          identityToken: 'mock-identity-token',
        );

        const scopes = [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName];
        when(mockAppleSignInService.getAppleIDCredential(
          scopes: scopes,
          webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
        )).thenAnswer((_) async => mockCredential);

        when(mockAuthUseCase.validateAppleToken('mock-identity-token'))
            .thenAnswer((_) async => 'mockuser@example.com');

        when(mockAuthUseCase.syncUser('Mock', 'mockuser@example.com', null))
            .thenAnswer((_) async => {});

        // Act
        await loginViewModel.signInWithApple();

        // Assert
        expect(loginViewModel.isSigningIn, true);
        expect(loginViewModel.errorMessage, null);
        verify(mockAppleSignInService.getAppleIDCredential(
          scopes: scopes,
          webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
        )).called(1);
        verify(mockAuthUseCase.validateAppleToken('mock-identity-token')).called(1);
        verify(mockAuthUseCase.syncUser('Mock', 'mockuser@example.com', null)).called(1);
      });

      test('should set errorMessage if identity token is null', () async {
        // Arrange
        final mockCredential = AuthorizationCredentialAppleID(
          userIdentifier: 'mock-user-id',
          givenName: 'Mock',
          familyName: 'User',
          email: 'mockuser@example.com',
          authorizationCode: 'mock-auth-code',
          identityToken: null,
        );

        const scopes = [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName];
        when(mockAppleSignInService.getAppleIDCredential(
          scopes: scopes,
          webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
        )).thenAnswer((_) async => mockCredential);

        // Act
        await loginViewModel.signInWithApple();

        // Assert
        expect(
          loginViewModel.errorMessage,
          'Sign in with Apple failed: Exception: Identity token not available in Apple credentials',
        );
        expect(loginViewModel.isSigningIn, false);
      });

      test('should set errorMessage on Apple sign-in error', () async {
        // Arrange
        const scopes = [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName];
        when(mockAppleSignInService.getAppleIDCredential(
          scopes: scopes,
          webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
        )).thenThrow(Exception('Apple sign-in error'));

        // Act
        await loginViewModel.signInWithApple();

        // Assert
        expect(
          loginViewModel.errorMessage,
          'Sign in with Apple failed: Exception: Apple sign-in error',
        );
        expect(loginViewModel.isSigningIn, false);
      });

      test('should handle error in authUseCase during validateAppleToken', () async {
        // Arrange
        final mockCredential = AuthorizationCredentialAppleID(
          userIdentifier: 'mock-user-id',
          givenName: 'Mock',
          familyName: 'User',
          email: 'mockuser@example.com',
          authorizationCode: 'mock-auth-code',
          identityToken: 'mock-identity-token',
        );

        const scopes = [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName];
        when(mockAppleSignInService.getAppleIDCredential(
          scopes: scopes,
          webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
        )).thenAnswer((_) async => mockCredential);

        // Simulate an error in validateAppleToken
        when(mockAuthUseCase.validateAppleToken('mock-identity-token'))
            .thenThrow(Exception('Auth use case error'));

        // Act
        await loginViewModel.signInWithApple();

        // Assert
        expect(
          loginViewModel.errorMessage,
          'Sign in with Apple failed: Exception: Auth use case error',
        );
        expect(loginViewModel.isSigningIn, false);
        verify(mockAppleSignInService.getAppleIDCredential(
          scopes: scopes,
          webAuthenticationOptions: anyNamed('webAuthenticationOptions'),
        )).called(1);
        verify(mockAuthUseCase.validateAppleToken('mock-identity-token')).called(1);
      });

    });
  });
}
