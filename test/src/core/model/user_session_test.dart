import 'package:flutter_test/flutter_test.dart';
import 'package:hydrodok/src/core/model/user_session.dart';

void main() {
  group('UserSession', () {
    group('constructor', () {
      test('defaults onboardingCompleted to true', () {
        final session = UserSession(
          uid: 'uid-1',
          email: 'test@test.com',
          fullName: 'Test User',
          phoneNumber: '09123456789',
          role: 'consumer',
          profileImageUrl: '',
          farmName: '',
          farmAddress: '',
          farmProduceTypes: [],
        );

        expect(session.uid, 'uid-1');
        expect(session.onboardingCompleted, isTrue);
      });

      test('accepts explicit onboardingCompleted value', () {
        final session = UserSession(
          uid: 'uid-1',
          email: 'test@test.com',
          fullName: 'Farmer',
          phoneNumber: '09123456789',
          role: 'farming',
          profileImageUrl: '',
          farmName: 'Green Acres',
          farmAddress: '123 Farm St',
          farmProduceTypes: ['Rice'],
          onboardingCompleted: false,
        );

        expect(session.onboardingCompleted, isFalse);
      });
    });

    group('fromJson', () {
      test('parses onboarding_completed: true', () {
        final session = UserSession.fromJson({
          'uid': 'uid-1',
          'email': 'farmer@test.com',
          'full_name': 'Farmer John',
          'contact_number': '09123456789',
          'role': 'farming',
          'avatar_url': '',
          'farm_name': 'Green Acres',
          'farm_address': '123 Farm St',
          'produce_types': ['Rice', 'Corn'],
          'onboarding_completed': true,
        });

        expect(session.onboardingCompleted, isTrue);
        expect(session.fullName, 'Farmer John');
        expect(session.farmName, 'Green Acres');
      });

      test('parses onboarding_completed: false', () {
        final session = UserSession.fromJson({
          'uid': 'uid-2',
          'email': 'newfarmer@test.com',
          'full_name': 'New Farmer',
          'contact_number': '09111111111',
          'role': 'farming',
          'avatar_url': '',
          'farm_name': '',
          'farm_address': '',
          'produce_types': [],
          'onboarding_completed': false,
        });

        expect(session.onboardingCompleted, isFalse);
      });

      test('defaults onboardingCompleted to true when key is missing', () {
        final session = UserSession.fromJson({
          'uid': 'uid-3',
          'email': 'consumer@test.com',
          'full_name': 'Consumer',
          'contact_number': '09222222222',
          'role': 'consumer',
          'avatar_url': '',
          'farm_name': '',
          'farm_address': '',
          'produce_types': [],
          // no onboarding_completed key
        });

        expect(session.onboardingCompleted, isTrue);
      });
    });

    group('toJson', () {
      test('includes onboarding_completed as true', () {
        final session = UserSession(
          uid: 'uid-1',
          email: 'test@test.com',
          fullName: 'Test User',
          phoneNumber: '09123456789',
          role: 'consumer',
          profileImageUrl: '',
          farmName: '',
          farmAddress: '',
          farmProduceTypes: [],
          onboardingCompleted: true,
        );

        final json = session.toJson();

        expect(json['onboarding_completed'], isTrue);
        expect(json['uid'], 'uid-1');
      });

      test('includes onboarding_completed as false', () {
        final session = UserSession(
          uid: 'uid-1',
          email: 'test@test.com',
          fullName: 'Test User',
          phoneNumber: '09123456789',
          role: 'farming',
          profileImageUrl: '',
          farmName: 'Farm',
          farmAddress: 'Addr',
          farmProduceTypes: [],
          onboardingCompleted: false,
        );

        final json = session.toJson();

        expect(json['onboarding_completed'], isFalse);
      });
    });
  });
}
