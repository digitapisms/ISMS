import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/feature_checker.dart';
import '../../../core/subscription/feature_guard.dart';
import '../../../core/subscription/upgrade_prompt_dialog.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../../school_registration/application/school_providers.dart';
import '../../subscription/application/subscription_providers.dart';
import '../application/student_providers.dart';
import '../domain/student.dart';
import 'add_student_screen.dart';
import 'bulk_import_screen.dart';
import 'student_detail_screen.dart';
import 'widgets/tenant_onboarding_checklist.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int? _selectedClassId;
  int? _selectedSectionId;
  String? _selectedStatus;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  List<Student> _filteredStudents = [];
  bool _isSearching = false;
  bool _hideOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final repo = ref.read(studentRepositoryProvider);
    final classes = await repo.fetchClasses();
    setState(() {
      _classes = classes;
    });
  }

  Future<void> _loadSections(int? classId) async {
    if (classId == null) {
      setState(() {
        _sections = [];
        _selectedSectionId = null;
      });
      return;
    }
    final repo = ref.read(studentRepositoryProvider);
    final sections = await repo.fetchSections(classId);
    setState(() {
      _sections = sections;
      _selectedSectionId = null;
    });
  }

  Future<void> _performSearch() async {
    final repo = ref.read(studentRepositoryProvider);
    final results = await repo.searchStudents(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      classId: _selectedClassId,
      sectionId: _selectedSectionId,
      status: _selectedStatus,
    );
    setState(() {
      _filteredStudents = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider);
    final tenantSchool = ref.watch(tenantContextProvider);
    final shouldShowOnboarding =
        !_hideOnboarding &&
        tenantSchool != null &&
        (authUser?.role == UserRole.principal ||
            authUser?.role == UserRole.admin);
    final onboardingStatus = shouldShowOnboarding
        ? ref.watch(tenantOnboardingProvider(tenantSchool.id))
        : null;
    final studentsAsync = ref.watch(studentsProvider);

    // Check if school context is available
    if (tenantSchool == null && authUser?.schoolId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Students')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'School Context Required',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select a school or ensure your account is linked to a school.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Perform search when filters change
    if (_isSearching) {
      _performSearch();
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Search students...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => _performSearch(),
              )
            : const Text('Students'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _selectedClassId = null;
                  _selectedSectionId = null;
                  _selectedStatus = null;
                  _filteredStudents = [];
                } else {
                  Future.delayed(Duration.zero, () {
                    _searchFocusNode.requestFocus();
                  });
                }
              });
            },
          ),
          FeatureProtectedButton(
            featureKey: 'bulk_import',
            tooltip: 'Bulk Import Students',
            child: IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const FeatureGuard(
                          featureKey: 'bulk_import',
                          child: BulkImportScreen(),
                        ),
                      ),
                    )
                    .then((_) {
                      ref.invalidate(studentsProvider);
                    });
              },
              tooltip: 'Bulk Import',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Feature usage indicator
          studentsAsync.when(
            data: (students) {
              final school = ref.watch(currentSchoolProvider);
              final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
              final checker = FeatureChecker(subscriptionRepo, school);
              final usageInfoAsync = ref.watch(
                FutureProvider((ref) async {
                  return checker.checkFeature(
                    'student_management',
                    currentUsage: students.length,
                  );
                }),
              );
              
              return usageInfoAsync.when(
                data: (result) {
                  if (result.limit != null) {
                    final isNearLimit = result.currentUsage != null &&
                        result.limit != null &&
                        result.currentUsage! >= (result.limit! * 0.8).round();
                    final isAtLimit = !result.isWithinLimit;
                    
                    if (isAtLimit || isNearLimit) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: isAtLimit
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.tertiaryContainer,
                        child: Row(
                          children: [
                            Icon(
                              isAtLimit ? Icons.warning : Icons.info_outline,
                              size: 20,
                              color: isAtLimit
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAtLimit
                                    ? 'Student limit reached: ${result.currentUsage}/${result.limit}'
                                    : 'Student limit: ${result.currentUsage}/${result.limit} (${((result.currentUsage! / result.limit!) * 100).round()}% used)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAtLimit
                                      ? Theme.of(context).colorScheme.onErrorContainer
                                      : Theme.of(context).colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                            if (isAtLimit)
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => UpgradePromptDialog(
                                      featureKey: 'student_management',
                                      currentPlan: school?.subscriptionPlan ?? 'free',
                                    ),
                                  );
                                },
                                child: const Text('Upgrade'),
                              ),
                          ],
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (shouldShowOnboarding)
            onboardingStatus!.when(
              data: (status) => status.isComplete
                  ? const SizedBox.shrink()
                  : TenantOnboardingChecklist(
                      status: status,
                      onDismiss: () {
                        setState(() {
                          _hideOnboarding = true;
                        });
                      },
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Onboarding status unavailable: $e'),
              ),
            ),
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Classes'),
                            ),
                            ..._classes.map(
                              (c) => DropdownMenuItem<int?>(
                                value: c['id'] as int,
                                child: Text(c['name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedClassId = v;
                            });
                            _loadSections(v);
                            _performSearch();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedSectionId,
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Sections'),
                            ),
                            ..._sections.map(
                              (s) => DropdownMenuItem<int?>(
                                value: s['id'] as int,
                                child: Text(s['name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedSectionId = v;
                            });
                            _performSearch();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedStatus = v;
                      });
                      _performSearch();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isSearching
                ? _buildStudentList(_filteredStudents)
                : studentsAsync.when(
                    data: (students) => _buildStudentList(students),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading students: $e'),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _FeatureProtectedFAB(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AddStudentScreen(),
            ),
          );
          if (created == true && mounted) {
            ref.invalidate(studentsProvider);
          }
        },
      ),
    );
  }

  Widget _buildStudentList(List<Student> students) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No students found' : 'No students yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final s = students[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
            ),
          ),
          title: Text(s.fullName.isEmpty ? s.admissionNo : s.fullName),
          subtitle: Text(
            [
              'Adm No: ${s.admissionNo}',
              if (s.className != null) 'Class: ${s.className}',
              if (s.sectionName != null) 'Section: ${s.sectionName}',
            ].join(' • '),
          ),
          trailing: s.status != null
              ? Chip(
                  label: Text(s.status!),
                  labelStyle: const TextStyle(fontSize: 12),
                )
              : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentDetailScreen(studentId: s.id),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: students.length,
    );
  }
}

/// FloatingActionButton that checks feature before showing
class _FeatureProtectedFAB extends ConsumerWidget {
  const _FeatureProtectedFAB({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(currentSchoolProvider);
    final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
    final studentsAsync = ref.watch(studentsProvider);
    
    return studentsAsync.when(
      data: (students) {
        final checker = FeatureChecker(subscriptionRepo, school);
        final featureCheckAsync = ref.watch(
          FutureProvider((ref) async {
            return checker.checkFeature(
              'student_management',
              currentUsage: students.length,
            );
          }),
        );
        
        return featureCheckAsync.when(
          data: (result) {
            if (result.canUse) {
              return FloatingActionButton(
                onPressed: onPressed,
                tooltip: result.limit != null
                    ? 'Add Student (${students.length}/${result.limit})'
                    : 'Add Student',
                child: const Icon(Icons.add),
              );
            }
            
            // Show disabled FAB with upgrade prompt
            return FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => UpgradePromptDialog(
                    featureKey: 'student_management',
                    currentPlan: school?.subscriptionPlan ?? 'free',
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              tooltip: result.statusMessage,
              child: const Icon(Icons.lock),
            );
          },
          loading: () => FloatingActionButton(
            onPressed: null,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => FloatingActionButton(
            onPressed: onPressed,
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => FloatingActionButton(
        onPressed: null,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}

