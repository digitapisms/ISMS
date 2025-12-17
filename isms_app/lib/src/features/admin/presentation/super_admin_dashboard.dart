import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../authentication/application/auth_providers.dart';
import '../../school_registration/application/school_providers.dart';
import '../../school_registration/domain/global_analytics.dart';
import '../../school_registration/domain/school.dart';
import '../../school_registration/domain/school_analytics.dart';
import '../../tenants/presentation/tenant_overview_tab.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../../core/theme/presentation/theme_settings_screen.dart';
import '../../../core/localization/widgets/language_selector.dart';
import 'plan_editor_view.dart';
import 'zoom_integration_screen.dart';
import 'google_meet_integration_screen.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  String? _planFilter;
  final Set<String> _selectedSchoolIds = {};
  bool _isSelectionMode = false;
  late TabController _tabController;

  SchoolListFilters get _filters => (
    status: _normalizeFilter(_statusFilter),
    subscriptionPlan: _normalizeFilter(_planFilter),
    query: _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim(),
  );

  String? _normalizeFilter(String? value) =>
      value == null || value == 'all' ? null : value;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final schoolsAsync = ref.watch(allSchoolsProvider(filters));
    final globalAnalyticsAsync = ref.watch(globalAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'ILMA',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        title: const Text('Super Admin'),
        actions: [
          // Theme Settings Button
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
              );
            },
            tooltip: 'Theme Settings',
          ),
          // Language Selector
          const LanguageSelector(),
          if (_isSelectionMode && _selectedSchoolIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Activate selected',
              onPressed: () => _bulkUpdateStatus('active'),
            ),
            IconButton(
              icon: const Icon(Icons.pause_circle),
              tooltip: 'Suspend selected',
              onPressed: () => _bulkUpdateStatus('suspended'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel selection',
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedSchoolIds.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select schools',
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onPressed: () => _exportSchools(schoolsAsync.value ?? []),
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'zoom') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ZoomIntegrationScreen(),
                  ),
                );
              } else if (value == 'google_meet') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GoogleMeetIntegrationScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'zoom',
                child: ListTile(
                  leading: Icon(Icons.video_call),
                  title: Text('Zoom Integration'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'google_meet',
                child: ListTile(
                  leading: Icon(Icons.video_call_outlined),
                  title: Text('Google Meet Integration'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Schools'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Plans'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Tenants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _buildFilterBar(context),
              Expanded(
                child: schoolsAsync.when(
                  data: (schools) => _buildContent(context, schools),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load schools',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$e',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(allSchoolsProvider(filters));
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
          _buildAnalyticsTab(globalAnalyticsAsync),
          _buildPlansTab(),
          const TenantOverviewTab(),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                labelText: 'Search schools',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          DropdownButton<String>(
            value: _statusFilter ?? 'all',
            onChanged: (value) {
              setState(() {
                _statusFilter = value == 'all' ? null : value;
              });
            },
            borderRadius: BorderRadius.circular(12),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Status')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
            ],
          ),
          DropdownButton<String>(
            value: _planFilter ?? 'all',
            onChanged: (value) {
              setState(() {
                _planFilter = value == 'all' ? null : value;
              });
            },
            borderRadius: BorderRadius.circular(12),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Plans')),
              DropdownMenuItem(value: 'free', child: Text('Free')),
              DropdownMenuItem(value: 'basic', child: Text('Basic')),
              DropdownMenuItem(value: 'premium', child: Text('Premium')),
              DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
            ],
          ),
          if (_isSelectionMode)
            Text(
              '${_selectedSchoolIds.length} selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<School> schools) {
    if (schools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No schools match your filters.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _planFilter = null;
                  _searchController.clear();
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    final total = schools.length;
    final pending = schools
        .where((s) => (s.status ?? 'pending') == 'pending')
        .length;
    final active = schools.where((s) => (s.status ?? '') == 'active').length;
    final suspended = schools
        .where((s) => (s.status ?? '') == 'suspended')
        .length;
    final expiringSoon = schools.where((s) {
      if (s.subscriptionExpiresAt == null) return false;
      final daysUntilExpiry = s.subscriptionExpiresAt!
          .difference(DateTime.now())
          .inDays;
      return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
    }).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _SummaryCard(
              title: 'Total schools',
              value: '$total',
              icon: Icons.apartment_outlined,
            ),
            _SummaryCard(
              title: 'Pending approvals',
              value: '$pending',
              icon: Icons.hourglass_top,
              color: Colors.orange,
            ),
            _SummaryCard(
              title: 'Active',
              value: '$active',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _SummaryCard(
              title: 'Suspended',
              value: '$suspended',
              icon: Icons.pause_circle_filled,
              color: Colors.red,
            ),
            if (expiringSoon > 0)
              _SummaryCard(
                title: 'Expiring soon',
                value: '$expiringSoon',
                icon: Icons.warning_amber,
                color: Colors.amber,
              ),
          ],
        ),
        const SizedBox(height: 24),
        ...schools.map((school) => _buildSchoolCard(context, school)),
      ],
    );
  }

  Widget _buildSchoolCard(BuildContext context, School school) {
    final colorScheme = Theme.of(context).colorScheme;
    final analyticsAsync = ref.watch(schoolAnalyticsProvider(school.id));
    final isSelected = _selectedSchoolIds.contains(school.id);
    final isExpiringSoon =
        school.subscriptionExpiresAt != null &&
        school.subscriptionExpiresAt!.difference(DateTime.now()).inDays > 0 &&
        school.subscriptionExpiresAt!.difference(DateTime.now()).inDays <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedSchoolIds.remove(school.id);
                  } else {
                    _selectedSchoolIds.add(school.id);
                  }
                });
              }
            : null,
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedSchoolIds.add(school.id);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedSchoolIds.add(school.id);
                          } else {
                            _selectedSchoolIds.remove(school.id);
                          }
                        });
                      },
                    ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: school.logoUrl != null
                        ? NetworkImage(school.logoUrl!)
                        : null,
                    child: school.logoUrl == null
                        ? Text(
                            school.name.isNotEmpty
                                ? school.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                school.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isExpiringSoon)
                              Tooltip(
                                message:
                                    'Subscription expires ${_formatDate(school.subscriptionExpiresAt!)}',
                                child: Icon(
                                  Icons.warning_amber,
                                  color: Colors.amber.shade700,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${school.email} • ${school.phone}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (school.city != null || school.country != null)
                          Text(
                            [
                              if (school.city != null) school.city,
                              if (school.country != null) school.country,
                            ].join(', '),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _StatusChip(
                              label: school.status ?? 'pending',
                              color: _statusColor(school.status),
                            ),
                            _StatusChip(
                              label:
                                  'Plan: ${school.subscriptionPlan ?? 'free'}',
                            ),
                            if (school.subscriptionExpiresAt != null)
                              _StatusChip(
                                label:
                                    'Expires ${_formatDate(school.subscriptionExpiresAt!)}',
                                color: isExpiringSoon ? Colors.amber : null,
                              ),
                            if (school.createdAt != null)
                              _StatusChip(
                                label:
                                    'Joined ${_formatRelativeDate(school.createdAt!)}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!_isSelectionMode)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'activate' || value == 'suspend') {
                          _confirmAndUpdateStatus(
                            schoolId: school.id,
                            schoolName: school.name,
                            status: value == 'activate'
                                ? 'active'
                                : 'suspended',
                          );
                        } else if (value == 'details') {
                          _openDetailsSheet(school);
                        } else if (value == 'subscription') {
                          _openSubscriptionSheet(school);
                        } else if (value == 'delete') {
                          _confirmDeleteSchool(school);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'activate',
                          child: ListTile(
                            leading: Icon(Icons.check_circle),
                            title: Text('Activate'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'suspend',
                          child: ListTile(
                            leading: Icon(Icons.pause_circle),
                            title: Text('Suspend'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'subscription',
                          child: ListTile(
                            leading: Icon(Icons.star_outline),
                            title: Text('Update subscription'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'details',
                          child: ListTile(
                            leading: Icon(Icons.visibility),
                            title: Text('View details'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete school',
                              style: TextStyle(color: Colors.red),
                            ),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              analyticsAsync.when(
                data: (analytics) => _AnalyticsRow(analytics: analytics),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Analytics unavailable: $e',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ),
              const SizedBox(height: 12),
              if (!_isSelectionMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _openDetailsSheet(school),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Details'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(AsyncValue<GlobalAnalytics> analyticsAsync) {
    return analyticsAsync.when(
      data: (analytics) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Global Analytics',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryCard(
                  title: 'Total Schools',
                  value: '${analytics.totalSchools}',
                  icon: Icons.apartment,
                ),
                _SummaryCard(
                  title: 'Total Students',
                  value: '${analytics.totalStudents}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _SummaryCard(
                  title: 'Total Applications',
                  value: '${analytics.totalApplications}',
                  icon: Icons.description,
                  color: Colors.purple,
                ),
                _SummaryCard(
                  title: 'Active Schools',
                  value: '${analytics.activeSchools}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _SummaryCard(
                  title: 'Pending Schools',
                  value: '${analytics.pendingSchools}',
                  icon: Icons.hourglass_top,
                  color: Colors.orange,
                ),
                _SummaryCard(
                  title: 'Total Users',
                  value: '${analytics.totalUsers}',
                  icon: Icons.person,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Subscription Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PlanDistributionRow(
                      plan: 'Free',
                      count: analytics.planDistribution['free'] ?? 0,
                      color: Colors.grey,
                    ),
                    _PlanDistributionRow(
                      plan: 'Basic',
                      count: analytics.planDistribution['basic'] ?? 0,
                      color: Colors.blue,
                    ),
                    _PlanDistributionRow(
                      plan: 'Premium',
                      count: analytics.planDistribution['premium'] ?? 0,
                      color: Colors.purple,
                    ),
                    _PlanDistributionRow(
                      plan: 'Enterprise',
                      count: analytics.planDistribution['enterprise'] ?? 0,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading analytics: $e'),
        ),
      ),
    );
  }

  Widget _buildPlansTab() {
    final plansAsync = ref.watch(allPlansProvider);
    final featuresAsync = ref.watch(allFeaturesProvider);

    return plansAsync.when(
      data: (plans) => featuresAsync.when(
        data: (features) => PlanEditorView(plans: plans, allFeatures: features),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading features',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('$e', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading plans',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('$e', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndUpdateStatus({
    required String schoolId,
    required String schoolName,
    required String status,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status == 'active' ? 'Activate' : 'Suspend'} School?'),
        content: Text(
          'Are you sure you want to ${status == 'active' ? 'activate' : 'suspend'} "$schoolName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(status == 'active' ? 'Activate' : 'Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(schoolId: schoolId, status: status);
    }
  }

  Future<void> _bulkUpdateStatus(String status) async {
    if (_selectedSchoolIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${status == 'active' ? 'Activate' : 'Suspend'} ${_selectedSchoolIds.length} Schools?',
        ),
        content: Text(
          'Are you sure you want to ${status == 'active' ? 'activate' : 'suspend'} ${_selectedSchoolIds.length} selected school(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(status == 'active' ? 'Activate All' : 'Suspend All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(schoolRepositoryProvider);
      int success = 0;
      int failed = 0;

      for (final schoolId in _selectedSchoolIds) {
        try {
          await repo.updateSchoolStatus(schoolId: schoolId, status: status);
          success++;
        } catch (e) {
          failed++;
          debugPrint('Failed to update $schoolId: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated $success school(s). ${failed > 0 ? '$failed failed.' : ''}',
            ),
            backgroundColor: failed > 0 ? Colors.orange : Colors.green,
          ),
        );
      }

      setState(() {
        _isSelectionMode = false;
        _selectedSchoolIds.clear();
      });

      ref.invalidate(allSchoolsProvider(_filters));
    } catch (e) {
      _showError('Bulk update failed: $e');
    }
  }

  Future<void> _confirmDeleteSchool(School school) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete School?'),
        content: Text(
          'Are you sure you want to delete "${school.name}"? This action cannot be undone and will delete all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(schoolRepositoryProvider);
        await repo.deleteSchool(schoolId: school.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('School deleted successfully')),
          );
        }
        ref.invalidate(allSchoolsProvider(_filters));
      } catch (e) {
        _showError('Failed to delete school: $e');
      }
    }
  }

  Future<void> _updateStatus({
    required String schoolId,
    required String status,
  }) async {
    try {
      final repo = ref.read(schoolRepositoryProvider);
      await repo.updateSchoolStatus(schoolId: schoolId, status: status);
      ref.invalidate(allSchoolsProvider(_filters));
      ref.invalidate(schoolAnalyticsProvider(schoolId));
      ref.invalidate(globalAnalyticsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School marked as $status'),
            backgroundColor: status == 'active' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to update status: $e');
    }
  }

  Future<void> _openSubscriptionSheet(School school) async {
    final plans = ['free', 'basic', 'premium', 'enterprise'];
    String selectedPlan = school.subscriptionPlan ?? 'free';
    DateTime? expiry = school.subscriptionExpiresAt;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Update subscription',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPlan,
                      items: plans
                          .map(
                            (plan) => DropdownMenuItem(
                              value: plan,
                              child: Text(plan.toUpperCase()),
                            ),
                          )
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Plan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a plan';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedPlan = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        expiry == null
                            ? 'Set expiry date'
                            : 'Expires on ${_formatDate(expiry!)}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 3),
                          ),
                          initialDate: expiry ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => expiry = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setModalState(() => expiry = null);
                      },
                      child: const Text('Remove expiry date'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        // Validate expiry date is not in the past
                        final expiryDate = expiry;
                        if (expiryDate != null &&
                            expiryDate.isBefore(DateTime.now())) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Expiry date cannot be in the past',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        try {
                          final repo = ref.read(schoolRepositoryProvider);
                          await repo.updateSchoolSubscription(
                            schoolId: school.id,
                            plan: selectedPlan,
                            expiresAt: expiry,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                          ref.invalidate(allSchoolsProvider(_filters));
                          ref.invalidate(globalAnalyticsProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Subscription updated'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          _showError('Failed to update subscription: $e');
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDetailsSheet(School school) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SchoolDetailSheet(
          school: school,
          onChangeStatus: (status) => _confirmAndUpdateStatus(
            schoolId: school.id,
            schoolName: school.name,
            status: status,
          ),
          onEditSubscription: () => _openSubscriptionSheet(school),
        ),
      ),
    );
  }

  void _exportSchools(List<School> schools) {
    final buffer = StringBuffer();
    buffer.writeln(
      'School Name,Email,Phone,Status,Plan,Expiry Date,City,Country',
    );
    for (final school in schools) {
      buffer.writeln(
        [
          '"${school.name}"',
          school.email,
          school.phone,
          school.status ?? 'pending',
          school.subscriptionPlan ?? 'free',
          school.subscriptionExpiresAt != null
              ? _formatDate(school.subscriptionExpiresAt!)
              : '',
          school.city ?? '',
          school.country ?? '',
        ].join(','),
      );
    }

    // In a real app, you'd use a file picker or share dialog
    // For now, show in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: SingleChildScrollView(
          child: SelectableText(buffer.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authStateProvider.notifier).signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showError('Logout failed: $e');
        }
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  Color? _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'pending':
      default:
        return null;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = color ?? colorScheme.primary;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: (color ?? colorScheme.primary).withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color?.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color ?? Theme.of(context).colorScheme.primary,
        fontSize: 11,
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({required this.analytics});

  final SchoolAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        _AnalyticsTile(label: 'Students', value: analytics.totalStudents),
        _AnalyticsTile(
          label: 'Pending applications',
          value: analytics.pendingApplications,
        ),
        _AnalyticsTile(label: 'Staff', value: analytics.staffCount),
        _AnalyticsTile(label: 'Teachers', value: analytics.teacherCount),
      ],
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  const _AnalyticsTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _PlanDistributionRow extends StatelessWidget {
  const _PlanDistributionRow({
    required this.plan,
    required this.count,
    required this.color,
  });

  final String plan;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              plan.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SchoolDetailSheet extends ConsumerWidget {
  const _SchoolDetailSheet({
    required this.school,
    required this.onChangeStatus,
    required this.onEditSubscription,
  });

  final School school;
  final Future<void> Function(String status) onChangeStatus;
  final VoidCallback onEditSubscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(schoolAnalyticsProvider(school.id));
    final onboardingAsync = ref.watch(tenantOnboardingProvider(school.id));
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (school.logoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      school.logoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(school.name, style: textTheme.headlineSmall),
                      if (school.slogan != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          school.slogan!,
                          style: textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${school.email} • ${school.phone}'),
            if (school.address != null || school.city != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (school.address != null) school.address,
                  if (school.city != null) school.city,
                  if (school.state != null) school.state,
                  if (school.country != null) school.country,
                ].where((e) => e != null).join(', '),
              ),
            ],
            if (school.website != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(school.website!),
                onPressed: () {
                  // Open website URL
                },
              ),
            ],
            if (school.schoolCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('School Code', style: textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                school.schoolCode!,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: school.schoolCode!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'School code copied to clipboard',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy code',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Text(
                            'Share this code with users for registration',
                            style: textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Overview', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            analyticsAsync.when(
              data: (analytics) => _AnalyticsRow(analytics: analytics),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Analytics unavailable: $e'),
            ),
            const SizedBox(height: 16),
            Text('Onboarding', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            onboardingAsync.when(
              data: (status) => Column(
                children: [
                  _ChecklistTile(
                    label: 'Profile complete',
                    isDone: status.profileComplete,
                  ),
                  _ChecklistTile(
                    label: 'Branding configured',
                    isDone: status.brandingComplete,
                  ),
                  _ChecklistTile(
                    label: 'Classes configured',
                    isDone: status.classesConfigured,
                  ),
                  _ChecklistTile(
                    label: 'Staff invited',
                    isDone: status.staffInvited,
                  ),
                  _ChecklistTile(
                    label: 'Applications live',
                    isDone: status.applicationsEnabled,
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Status unavailable: $e'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: () => onChangeStatus('active'),
                  child: const Text('Activate'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => onChangeStatus('suspended'),
                  child: const Text('Suspend'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEditSubscription,
                  child: const Text('Edit subscription'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.label, required this.isDone});

  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isDone ? colorScheme.primary : colorScheme.outline,
      ),
      title: Text(label),
    );
  }
}
