import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibility_provider.dart';
import '../accessibility_service.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);
    final notifier = ref.read(accessibilitySettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Screen Reader Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Screen Reader',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable screen reader support for better accessibility',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Screen Reader'),
                    value: settings.screenReaderEnabled,
                    onChanged: (value) => notifier.toggleScreenReader(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // High Contrast Mode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'High Contrast Mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enhance visibility with high contrast colors',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable High Contrast Mode'),
                    value: settings.highContrastMode,
                    onChanged: (value) => notifier.toggleHighContrast(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Text Scaling
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text Size',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adjust text size for better readability',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: settings.textScalingFactor,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${(settings.textScalingFactor * 100).round()}%',
                    onChanged: (value) => notifier.setTextScaling(value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('Smaller'), Text('Larger')],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Keyboard Navigation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keyboard Navigation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable keyboard navigation support',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Keyboard Navigation'),
                    value: settings.keyboardNavigation,
                    onChanged: (value) => notifier.toggleKeyboardNavigation(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use Tab to navigate, Enter/Space to select',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Text-to-Speech
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text-to-Speech',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable text-to-speech functionality',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Text-to-Speech'),
                    value: settings.textToSpeechEnabled,
                    onChanged: (value) => notifier.toggleTextToSpeech(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Speak Current Screen'),
                onPressed: () {
                  final accessibilityService = ref.read(accessibilityServiceProvider);
                  final settings = ref.read(accessibilitySettingsProvider);
                  
                  if (settings.textToSpeechEnabled) {
                    accessibilityService.speak(
                      'Accessibility Settings Screen. Screen Reader: \${settings.screenReaderEnabled ? 'Enabled' : 'Disabled'}. '
                      'High Contrast Mode: \${settings.highContrastMode ? 'Enabled' : 'Disabled'}. '
                      'Keyboard Navigation: \${settings.keyboardNavigation ? 'Enabled' : 'Disabled'}. '
                      'Text Size: \${(settings.textScalingFactor * 100).round()} percent.',
                      volume: 0.8,
                      rate: 0.5,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enable Text-to-Speech first'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ActionChip(
                label: const Text('Test Screen Reader'),
                onPressed: () {
                  final accessibilityService = ref.read(accessibilityServiceProvider);
                  final settings = ref.read(accessibilitySettingsProvider);
                  
                  if (settings.screenReaderEnabled) {
                    accessibilityService.speak(
                      'Screen Reader Test. This is a test of the screen reader functionality. '
                      'If you can hear this message, the screen reader is working correctly. '
                      'The screen reader will read all interactive elements and provide '
                      'navigation assistance throughout the application. '
                      'You can use keyboard navigation with Tab and arrow keys to move between elements. '
                      'Press Enter or Space to activate buttons and controls.',
                      volume: 0.8,
                      rate: 0.5,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enable Screen Reader first'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ActionChip(
                label: const Text('Reset to Default'),
                onPressed: () {
                  final notifier = ref.read(accessibilitySettingsProvider.notifier);
                  notifier.updateSettings(const AccessibilitySettings());

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Accessibility settings reset to defaults'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
