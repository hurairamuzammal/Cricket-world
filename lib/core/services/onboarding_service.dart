import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';

class OnboardingService extends ChangeNotifier {
  static const String _baseOnboardingKey = 'onboarding_completed';

  bool _isOnboardingCompleted = false;
  late SharedPreferences _prefs;
  late String _deviceHash;

  bool get isOnboardingCompleted => _isOnboardingCompleted;

  /// Initialize the service, get device hash, and load state
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Get unique device hash for local registration
    final deviceService = DeviceService();
    _deviceHash = await deviceService.getDeviceHash();
    debugPrint('Device Hash for Onboarding: $_deviceHash');

    await _loadOnboardingState();
  }

  /// Load onboarding state using the device-specific key
  Future<void> _loadOnboardingState() async {
    // Check if this specific device hash is registered locally
    // We check both the generic key (legacy) and the device-specific key
    final deviceKey = '${_baseOnboardingKey}_$_deviceHash';

    _isOnboardingCompleted =
        (_prefs.getBool(deviceKey) ?? false) ||
        (_prefs.getBool(_baseOnboardingKey) ?? false);

    notifyListeners();
  }

  /// Mark onboarding as completed for this device
  Future<void> completeOnboarding() async {
    if (!_isOnboardingCompleted) {
      _isOnboardingCompleted = true;

      // key tied to the device hash
      final deviceKey = '${_baseOnboardingKey}_$_deviceHash';

      await _prefs.setBool(deviceKey, true);
      await _prefs.setBool(
        _baseOnboardingKey,
        true,
      ); // Keep generic key for fallback

      debugPrint('Onboarding completed for device: $_deviceHash');
      notifyListeners();
    }
  }

  /// Reset onboarding state
  Future<void> resetOnboarding() async {
    _isOnboardingCompleted = false;
    final deviceKey = '${_baseOnboardingKey}_$_deviceHash';

    await _prefs.setBool(deviceKey, false);
    await _prefs.setBool(_baseOnboardingKey, false);

    notifyListeners();
  }

  /// Check if this is the first app launch
  bool get isFirstLaunch => !_isOnboardingCompleted;
}
