import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notification_providers.dart';
import '../domain/notification.dart';
import '../domain/notification_template.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final Map<String, Map<NotificationType, bool>> _preferences = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(notificationTemplatesProvider(null));
    final preferencesAsync = ref.watch(
      notificationPreferencesProvider(widget.userId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: templatesAsync.when(
        data: (templates) {
          // Group templates by category
          final templatesByCategory = <String, List<NotificationTemplate>>{};
          for (final template in templates) {
            final category = template.category ?? 'other';
            templatesByCategory.putIfAbsent(category, () => []).add(template);
          }

          return preferencesAsync.when(
            data: (preferences) {
              // Load preferences into state
              for (final pref in preferences) {
                _preferences[pref.templateKey] = {
                  NotificationType.email: pref.emailEnabled,
                  NotificationType.sms: pref.smsEnabled,
                  NotificationType.push: pref.pushEnabled,
                };
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Preferences',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you want to receive notifications for different events.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ...templatesByCategory.entries.map((entry) {
                      final category = entry.key;
                      final categoryTemplates = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.toUpperCase().replaceAll('_', ' '),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...categoryTemplates.map((template) {
                            return _PreferenceCard(
                              template: template,
                              preferences:
                                  _preferences[template.templateKey] ??
                                  {
                                    NotificationType.email: true,
                                    NotificationType.sms: false,
                                    NotificationType.push: true,
                                  },
                              onChanged:
                                  ((NotificationType type, bool value) {
                                        setState(() {
                                          _preferences.putIfAbsent(
                                            template.templateKey,
                                            () => {
                                              NotificationType.email: true,
                                              NotificationType.sms: false,
                                              NotificationType.push: true,
                                            },
                                          );
                                          _preferences[template
                                                  .templateKey]![type] =
                                              value;
                                        });
                                      })
                                      as ValueChanged<(NotificationType, bool)>,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : () => _savePreferences(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Preferences'),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(notificationRepositoryProvider);

      for (final entry in _preferences.entries) {
        final templateKey = entry.key;
        final prefs = entry.value;

        await repo.updatePreference(
          userId: widget.userId,
          templateKey: templateKey,
          emailEnabled: prefs[NotificationType.email],
          smsEnabled: prefs[NotificationType.sms],
          pushEnabled: prefs[NotificationType.push],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
      }

      // Refresh preferences
      ref.invalidate(notificationPreferencesProvider(widget.userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.template,
    required this.preferences,
    required this.onChanged,
  });

  final NotificationTemplate template;
  final Map<NotificationType, bool> preferences;
  final ValueChanged<(NotificationType, bool)> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (template.description != null) ...[
              const SizedBox(height: 4),
              Text(
                template.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Email'),
              subtitle: const Text('Receive via email'),
              value: preferences[NotificationType.email] ?? true,
              onChanged: (value) => onChanged((NotificationType.email, value)),
            ),
            SwitchListTile(
              title: const Text('SMS'),
              subtitle: const Text('Receive via SMS (requires phone number)'),
              value: preferences[NotificationType.sms] ?? false,
              onChanged: (value) => onChanged((NotificationType.sms, value)),
            ),
            SwitchListTile(
              title: const Text('Push Notification'),
              subtitle: const Text('Receive push notifications in app'),
              value: preferences[NotificationType.push] ?? true,
              onChanged: (value) => onChanged((NotificationType.push, value)),
            ),
          ],
        ),
      ),
    );
  }
}
