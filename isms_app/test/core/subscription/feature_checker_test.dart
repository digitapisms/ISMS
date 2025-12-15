import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:isms_app/src/core/subscription/feature_checker.dart';
import 'package:isms_app/src/features/school_registration/domain/school.dart';
import 'package:isms_app/src/features/subscription/data/subscription_repository.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

const _school = School(
  id: 'school-1',
  name: 'Test School',
  email: 'school@example.com',
  phone: '+123456789',
  subscriptionPlan: 'premium',
);

void main() {
  group('FeatureChecker', () {
    late _MockSubscriptionRepository repository;
    late FeatureChecker checker;

    setUp(() {
      repository = _MockSubscriptionRepository();
      checker = FeatureChecker(repository, _school);
    });

    test('returns disabled result when feature is not enabled', () async {
      when(() => repository.isFeatureEnabled(any(), any()))
          .thenAnswer((_) async => false);

      final result = await checker.checkFeature('student_management');

      expect(result.isEnabled, isFalse);
      expect(result.canUse, isFalse);
      expect(result.statusMessage, contains('Enterprise plan'));
      verify(() => repository.isFeatureEnabled('premium', 'student_management'))
          .called(1);
      verifyNever(() => repository.getFeatureLimit(any(), any()));
    });

    test('respects limits when feature is enabled', () async {
      when(() => repository.isFeatureEnabled(any(), any()))
          .thenAnswer((_) async => true);
      when(() => repository.getFeatureLimit(any(), any()))
          .thenAnswer((_) async => 2);

      final result = await checker.checkFeature(
        'student_management',
        currentUsage: 2,
      );

      expect(result.isEnabled, isTrue);
      expect(result.isWithinLimit, isFalse);
      expect(result.canUse, isFalse);
      expect(result.limit, 2);
      expect(result.currentUsage, 2);
      verify(() => repository.isFeatureEnabled('premium', 'student_management'))
          .called(1);
      verify(() => repository.getFeatureLimit('premium', 'student_management'))
          .called(1);
    });

    test('fails open when repository throws', () async {
      when(() => repository.isFeatureEnabled(any(), any()))
          .thenThrow(Exception('boom'));

      final result = await checker.checkFeature('student_management');

      expect(result.isEnabled, isTrue);
      expect(result.canUse, isTrue);
      expect(result.statusMessage, 'Available');
    });
  });
}

