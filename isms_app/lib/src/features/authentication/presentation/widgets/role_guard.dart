import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';
import '../../domain/user_role.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    if (allowedRoles.contains(user.role)) {
      return child;
    }

    return fallback ??
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'You do not have permission to view this section.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
  }
}
