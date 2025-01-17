import 'package:domain/entities/user.dart';
import 'package:domain/mocks/auth_usecase_mock.dart';
import 'package:domain/mocks/user_usecase_mock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:domain/mocks/chat_usecase_mock.dart';
import 'package:domain/mocks/chatsession_usecase_mock.dart';
import 'package:domain/mocks/functiontool_usecase_mock.dart';

void main() {
  group('ChatViewModel Tests', () {
    late MockChatUseCase mockChatUseCase;
    late MockChatSessionUseCase mockChatSessionUseCase;
    late MockFunctionToolsUseCase mockFunctionToolsUseCase;
    late MockAuthUseCase mockAuthUseCase;
    late MockUserUseCase mockUserUseCase;
    late ChatViewModel chatViewModel;

    setUp(() {
      // Initialize the mocks and view model before each test
      mockAuthUseCase = MockAuthUseCase();
      mockUserUseCase = MockUserUseCase();
      mockChatUseCase = MockChatUseCase();
      mockChatSessionUseCase = MockChatSessionUseCase();
      mockFunctionToolsUseCase = MockFunctionToolsUseCase();
      chatViewModel = ChatViewModel(
        chatUseCase: mockChatUseCase,
        authUseCase: mockAuthUseCase,
        userUserCase: mockUserUseCase,
        chatSessionUseCase: mockChatSessionUseCase,
        functionToolsUseCase: mockFunctionToolsUseCase,
      );
    });

    tearDown(() {
      // Clean up resources or reset mock state after each test
      reset(mockAuthUseCase);
      reset(mockUserUseCase);
      reset(mockChatUseCase);
      reset(mockChatSessionUseCase);
      reset(mockFunctionToolsUseCase);
    });

    group('fetchAuthSessionNew', () {
      test('fetchAuthSessionNew sets isLoggedIn to true and fetches user when logged in', () async {
        // Arrange
        when(mockAuthUseCase.isLoggedIn()).thenAnswer((_) async => true);
        final mockUser =
            User(name: 'Test User', email: '123@gmail.com', avatarUrl: 'test-avatar.png');
        when(mockUserUseCase.fetchMe()).thenAnswer((_) async => mockUser);

        // Act
        await chatViewModel.fetchAuthSessionNew();

        // Assert
        expect(chatViewModel.isLoggedIn, true);
        expect(chatViewModel.user, mockUser);
        verify(mockAuthUseCase.isLoggedIn()).called(1);
        verify(mockUserUseCase.fetchMe()).called(1);
      });

      test('fetchAuthSessionNew handles exception and resets state', () async {
        // Arrange
        when(mockAuthUseCase.isLoggedIn()).thenThrow(Exception('Auth error'));

        // Act
        await chatViewModel.fetchAuthSessionNew();

        // Assert
        expect(chatViewModel.isLoggedIn, false);
        expect(chatViewModel.user, null);
        verify(mockAuthUseCase.isLoggedIn()).called(1);
      });

      test('fetchAuthSessionNew sets isLoggedIn to false and user to null when not logged in',
          () async {
        // Arrange
        when(mockAuthUseCase.isLoggedIn()).thenAnswer((_) async => false);

        // Act
        await chatViewModel.fetchAuthSessionNew();

        // Assert
        expect(chatViewModel.isLoggedIn, false);
        expect(chatViewModel.user, null);
        verify(mockAuthUseCase.isLoggedIn()).called(1);
        verifyNever(mockUserUseCase.fetchMe());
      });
    });
  });
}
