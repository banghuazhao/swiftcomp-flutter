import 'package:mockito/mockito.dart';

import '../entities/user.dart';
import '../usecases/auth_usecase.dart';

class MockAuthUseCase extends Mock implements AuthUseCase {
  @override
  Future<String> login(String email, String password) =>
      super.noSuchMethod(Invocation.method(#login, [email, password]),
          returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));

  @override
  Future<bool> validateGoogleToken(String idToken) =>
      super.noSuchMethod(Invocation.method(#validateGoogleToken, [idToken]),
          returnValue: Future.value(true),
          returnValueForMissingStub: Future.value(true));

  @override
  Future<String> syncUser(String? displayName, String email, String? photoUrl) =>
      super.noSuchMethod(Invocation.method(#syncUser, [displayName, email, photoUrl]),
          returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));

  @override
  Future<String> validateAppleToken(String identityToken) =>
      super.noSuchMethod(Invocation.method(#validateAppleToken, [identityToken]),
         returnValue: Future.value(''),
          returnValueForMissingStub: Future.value(''));

  @override
  Future<User> signup(String email, String password, String verificationCode, {String? name}) =>
      super.noSuchMethod(
          Invocation.method(#signup, [email, password, verificationCode, name]),
          returnValue: Future.value(User(name: name, email: email)),
          returnValueForMissingStub: Future.value(User(name: 'default', email: email)));

  @override
  Future<void> sendSignupVerificationCode(String email) =>
      super.noSuchMethod(
        Invocation.method(#sendSignupVerificationCode, [email]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );
}





