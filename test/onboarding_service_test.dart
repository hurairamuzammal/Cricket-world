import 'package:flutter_test/flutter_test.dart';
import 'package:world_of_cricket/core/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    test('should create service instance', () {
      final onboardingService = OnboardingService();
      expect(onboardingService, isNotNull);
      expect(onboardingService.isOnboardingCompleted, false);
      expect(onboardingService.isFirstLaunch, true);
    });
  });
}
