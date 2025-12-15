import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../authentication/domain/user_role.dart';
import '../../authentication/presentation/widgets/role_guard.dart';
import '../../tenants/application/tenant_providers.dart';
import '../../tenants/domain/tenant.dart';
import '../../tenants/domain/tenant_settings.dart';

class TenantOverviewTab extends ConsumerStatefulWidget {
  const TenantOverviewTab({super.key});

  @override
  ConsumerState<TenantOverviewTab> createState() => _TenantOverviewTabState();
}

class _TenantOverviewTabState extends ConsumerState<TenantOverviewTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TenantFilter get _filters => (
    status: _status == null || _status == 'all' ? null : _status,
    query: _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsProvider(_filters));

    return RoleGuard(
      allowedRoles: const [UserRole.superAdmin],
      child: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: tenantsAsync.when(
              data: (tenants) {
                if (tenants.isEmpty) {
                  return const Center(child: Text('No tenants found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    return _TenantCard(
                      tenant: tenant,
                      onEdit: () => _showSettingsDialog(tenant),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: tenants.length,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load tenants',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('$e', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(tenantsProvider(_filters));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tenants by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _status ?? 'all',
            underline: const SizedBox(),
            onChanged: (value) {
              setState(() {
                _status = value;
              });
            },
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All statuses')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog(Tenant tenant) async {
    final repo = ref.read(tenantRepositoryProvider);
    final settingsFuture = repo.fetchSettings(tenant.id);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<TenantSettings?>(
          future: settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                content: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final existing = snapshot.data;
            final timezoneController = TextEditingController(
              text: existing?.timezone ?? tenant.timezone ?? 'Asia/Karachi',
            );
            final localeController = TextEditingController(
              text: existing?.locale ?? tenant.locale ?? 'en',
            );
            final currencyController = TextEditingController(
              text: existing?.currency ?? tenant.currency ?? 'PKR',
            );

            return AlertDialog(
              title: Text('Tenant settings - ${tenant.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: timezoneController,
                    decoration: const InputDecoration(labelText: 'Timezone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: localeController,
                    decoration: const InputDecoration(labelText: 'Locale'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final payload = <String, dynamic>{
                      'timezone': timezoneController.text.trim(),
                      'locale': localeController.text.trim(),
                      'currency': currencyController.text.trim(),
                    };
                    Navigator.of(context).pop();
                    await _saveTenantSettings(tenant, payload);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveTenantSettings(
    Tenant tenant,
    Map<String, dynamic> payload,
  ) async {
    final repo = ref.read(tenantRepositoryProvider);
    try {
      await repo.updateSettings(schoolId: tenant.id, payload: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tenant settings updated for ${tenant.name}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant, required this.onEdit});

  final Tenant tenant;
  final VoidCallback onEdit;

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return DateFormat.yMMMd().format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        tenant.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(tenant.email),
                    ],
                  ),
                ),
                _StatusPill(status: tenant.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'Plan',
                  value: tenant.subscriptionPlan.toUpperCase(),
                ),
                _InfoChip(label: 'Timezone', value: tenant.timezone ?? '—'),
                _InfoChip(label: 'Locale', value: tenant.locale ?? '—'),
                _InfoChip(label: 'Currency', value: tenant.currency ?? '—'),
                _InfoChip(
                  label: 'Renews',
                  value: _formatDate(tenant.subscriptionExpiresAt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'suspended':
        color = Theme.of(context).colorScheme.error;
        break;
      default:
        color = Theme.of(context).colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
