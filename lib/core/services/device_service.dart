import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Gets a unique device ID for Windows or Android
  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // androidId is fairly stable across app reinstalls (but not factory resets)
        return androidInfo.id;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        // deviceId on Windows is typically the machine GUID
        return windowsInfo.deviceId;
      }
      return 'unknown_device';
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return 'error_device_id';
    }
  }

  /// Generates a SHA-256 hash of the device ID for "registration" or tracking
  Future<String> getDeviceHash() async {
    final deviceId = await getDeviceId();
    final bytes = utf8.encode(deviceId);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Returns device info platform specific metadata
  Future<Map<String, String>> getDeviceMetadata() async {
    final metadata = <String, String>{};
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        metadata['model'] = androidInfo.model;
        metadata['brand'] = androidInfo.brand;
        metadata['version'] = androidInfo.version.release;
        metadata['platform'] = 'Android';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        metadata['computerName'] = windowsInfo.computerName;
        metadata['numberOfCores'] = windowsInfo.numberOfCores.toString();
        metadata['platform'] = 'Windows';
      }
    } catch (e) {
      debugPrint('Error getting device metadata: $e');
    }
    return metadata;
  }
}
