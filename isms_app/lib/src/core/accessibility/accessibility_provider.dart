import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility_service.dart';

final accessibilityServiceProvider = Provider<AccessibilityService>((ref) {
  return AccessibilityService();
});

final accessibilitySettingsProvider = StateNotifierProvider<AccessibilitySettingsNotifier, AccessibilitySettings>((ref) {
  return AccessibilitySettingsNotifier();
});

class AccessibilitySettings {
  final bool screenReaderEnabled;
  final bool highContrastMode;
  final bool textToSpeechEnabled;
  final double textScalingFactor;
  final bool keyboardNavigation;
  
  const AccessibilitySettings({
    this.screenReaderEnabled = true,
    this.highContrastMode = false,
    this.textToSpeechEnabled = false,
    this.textScalingFactor = 1.0,
    this.keyboardNavigation = false,
  });
  
  AccessibilitySettings copyWith({
    bool? screenReaderEnabled,
    bool? highContrastMode,
    bool? textToSpeechEnabled,
    double? textScalingFactor,
    bool? keyboardNavigation,
  }) {
    return AccessibilitySettings(
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      textToSpeechEnabled: textToSpeechEnabled ?? this.textToSpeechEnabled,
      textScalingFactor: textScalingFactor ?? this.textScalingFactor,
      keyboardNavigation: keyboardNavigation ?? this.keyboardNavigation,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'screenReaderEnabled': screenReaderEnabled,
      'highContrastMode': highContrastMode,
      'textToSpeechEnabled': textToSpeechEnabled,
      'textScalingFactor': textScalingFactor,
      'keyboardNavigation': keyboardNavigation,
    };
  }
  
  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      screenReaderEnabled: map['screenReaderEnabled'] as bool? ?? true,
      highContrastMode: map['highContrastMode'] as bool? ?? false,
      textToSpeechEnabled: map['textToSpeechEnabled'] as bool? ?? false,
      textScalingFactor: (map['textScalingFactor'] as num?)?.toDouble() ?? 1.0,
      keyboardNavigation: map['keyboardNavigation'] as bool? ?? false,
    );
  }
}

class AccessibilitySettingsNotifier extends StateNotifier<AccessibilitySettings> {
  AccessibilitySettingsNotifier() : super(const AccessibilitySettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsMap = {
      'screenReaderEnabled': prefs.getBool('screenReaderEnabled') ?? true,
      'highContrastMode': prefs.getBool('highContrastMode') ?? false,
      'textToSpeechEnabled': prefs.getBool('textToSpeechEnabled') ?? false,
      'textScalingFactor': prefs.getDouble('textScalingFactor') ?? 1.0,
      'keyboardNavigation': prefs.getBool('keyboardNavigation') ?? false,
    };
    
    state = AccessibilitySettings.fromMap(settingsMap);
  }
  
  Future<void> updateSettings(AccessibilitySettings newSettings) async {
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('screenReaderEnabled', newSettings.screenReaderEnabled);
    await prefs.setBool('highContrastMode', newSettings.highContrastMode);
    await prefs.setBool('textToSpeechEnabled', newSettings.textToSpeechEnabled);
    await prefs.setDouble('textScalingFactor', newSettings.textScalingFactor);
    await prefs.setBool('keyboardNavigation', newSettings.keyboardNavigation);
  }
  
  Future<void> toggleScreenReader() async {
    final newSettings = state.copyWith(
      screenReaderEnabled: !state.screenReaderEnabled,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> toggleHighContrast() async {
    final newSettings = state.copyWith(
      highContrastMode: !state.highContrastMode,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> toggleTextToSpeech() async {
    final newSettings = state.copyWith(
      textToSpeechEnabled: !state.textToSpeechEnabled,
    );
    await updateSettings(newSettings);
  }
  
  Future<void> setTextScaling(double factor) async {
    final newSettings = state.copyWith(
      textScalingFactor: factor.clamp(0.5, 2.0),
    );
    await updateSettings(newSettings);
  }
  
  Future<void> toggleKeyboardNavigation() async {
    final newSettings = state.copyWith(
      keyboardNavigation: !state.keyboardNavigation,
    );
    await updateSettings(newSettings);
  }
}