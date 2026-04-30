import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/services/auth_service.dart';

MockUser _user({String uid = 'uid1', String email = 'test@example.com'}) =>
    MockUser(uid: uid, email: email);

void main() {
  group('AuthService', () {
    test('currentUser is null when not signed in', () {
      final service = AuthService(auth: MockFirebaseAuth(signedIn: false));
      expect(service.currentUser, isNull);
    });

    test('currentUser is non-null when signed in', () {
      final service = AuthService(
          auth: MockFirebaseAuth(mockUser: _user(), signedIn: true));
      expect(service.currentUser, isNotNull);
    });

    test('authStateChanges emits null when not signed in', () {
      final service = AuthService(auth: MockFirebaseAuth(signedIn: false));
      expect(service.authStateChanges, emits(isNull));
    });

    test('authStateChanges emits User when signed in', () {
      final service = AuthService(
          auth: MockFirebaseAuth(mockUser: _user(), signedIn: true));
      expect(service.authStateChanges, emits(isNotNull));
    });

    test('signIn returns UserCredential with correct uid', () async {
      final service = AuthService(
          auth: MockFirebaseAuth(mockUser: _user(uid: 'abc'), signedIn: false));
      final cred = await service.signIn('test@example.com', 'password');
      expect(cred.user?.uid, 'abc');
    });

    test('currentUser is non-null after signIn', () async {
      final auth = MockFirebaseAuth(mockUser: _user(), signedIn: false);
      final service = AuthService(auth: auth);
      await service.signIn('test@example.com', 'password');
      expect(service.currentUser, isNotNull);
    });

    test('signOut sets currentUser to null', () async {
      final auth = MockFirebaseAuth(mockUser: _user(), signedIn: true);
      final service = AuthService(auth: auth);
      await service.signOut();
      expect(service.currentUser, isNull);
    });
  });
}
