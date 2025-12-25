import 'package:flutter/material.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<String> vibrationMode = ValueNotifier<String>('Soft pulse');
  final ValueNotifier<String> themeMode = ValueNotifier<String>('System Default');

  // Helper to toggle notifications
  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
  }

  // Set vibration mode
  void setVibration(String mode) {
    vibrationMode.value = mode;
  }
}
