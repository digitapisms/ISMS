import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/feature_guard.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../../school_registration/application/school_providers.dart';
import '../application/student_providers.dart';
import '../domain/student.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => const _AddStudentDialog(),
          );
          ref.invalidate(studentsProvider);
        },
        child: const Icon(Icons.add),
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

class _AddStudentDialog extends ConsumerStatefulWidget {
  const _AddStudentDialog();

  @override
  ConsumerState<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _admissionController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _admissionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(studentRepositoryProvider);
      await repo.createStudent(
        admissionNo: _admissionController.text.trim(),
        fullName: _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Failed to create student: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Student'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _admissionController,
              decoration: const InputDecoration(labelText: 'Admission No'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
