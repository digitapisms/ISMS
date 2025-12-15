import 'package:flutter/material.dart';

import '../../../school_registration/domain/tenant_onboarding_status.dart';

class TenantOnboardingChecklist extends StatelessWidget {
  const TenantOnboardingChecklist({
    super.key,
    required this.status,
    this.onDismiss,
  });

  final TenantOnboardingStatus status;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final steps = [
      (
        'Complete school profile',
        'Add address, slogan and contact details',
        status.profileComplete,
      ),
      (
        'Upload branding',
        'Add logo and theme colors for your tenant',
        status.brandingComplete,
      ),
      (
        'Configure classes & sections',
        'Create classes before admitting students',
        status.classesConfigured,
      ),
      (
        'Invite staff & teachers',
        'Add admin, staff or teacher accounts',
        status.staffInvited,
      ),
      (
        'Publish application form',
        'Collect applications from parents/students',
        status.applicationsEnabled,
      ),
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenant onboarding',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.isComplete
                            ? 'All setup steps are complete.'
                            : 'Finish onboarding to unlock the full experience.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: status.progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.map(
              (item) => _ChecklistRow(
                title: item.$1,
                subtitle: item.$2,
                isDone: item.$3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  final String title;
  final String subtitle;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
