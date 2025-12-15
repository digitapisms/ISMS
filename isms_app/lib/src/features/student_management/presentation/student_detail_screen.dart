import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/student_providers.dart';
import '../domain/student.dart';
import 'edit_student_screen.dart';
import 'add_family_dialog.dart';
import 'add_emergency_dialog.dart';
import 'student_id_card_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentIdCardScreen(studentId: studentId),
                ),
              );
            },
            tooltip: 'View ID Card',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final student = await ref.read(
                studentDetailProvider(studentId).future,
              );
              if (student != null && context.mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditStudentScreen(student: student),
                  ),
                );
                ref.invalidate(studentDetailProvider(studentId));
              }
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student not found'));
          }
          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                _StudentHeader(student: student),
                const TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Documents'),
                    Tab(text: 'Family'),
                    Tab(text: 'Emergency'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(student: student),
                      _DocumentsTab(studentId: studentId),
                      _FamilyTab(studentId: studentId),
                      _EmergencyTab(studentId: studentId),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              student.fullName.isNotEmpty
                  ? student.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName.isEmpty
                      ? student.admissionNo
                      : student.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text('Admission No: ${student.admissionNo}'),
                if (student.className != null)
                  Text(
                    'Class: ${student.className}${student.sectionName != null ? ' - ${student.sectionName}' : ''}',
                  ),
                if (student.status != null)
                  Chip(
                    label: Text(student.status!),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Personal Information',
          items: [
            if (student.dob != null)
              _InfoItem('Date of Birth', _formatDate(student.dob!)),
            if (student.gender != null) _InfoItem('Gender', student.gender!),
            if (student.bloodGroup != null)
              _InfoItem('Blood Group', student.bloodGroup!),
          ],
        ),
        if (student.medicalInfo != null)
          _InfoCard(
            title: 'Medical Information',
            items: [_InfoItem('Notes', student.medicalInfo!)],
          ),
        _InfoCard(
          title: 'Academic Information',
          items: [
            if (student.className != null)
              _InfoItem('Class', student.className!),
            if (student.sectionName != null)
              _InfoItem('Section', student.sectionName!),
            _InfoItem('Status', student.status ?? 'Active'),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.items});

  final String title;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;
}

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(studentDocumentsProvider(studentId));

    return documentsAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No documents uploaded',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(doc['document_type'] as String? ?? 'Document'),
                subtitle: Text(
                  'Uploaded: ${_formatDate(DateTime.parse(doc['uploaded_at'] as String))}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Download document
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FamilyTab extends ConsumerWidget {
  const _FamilyTab({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(studentFamilyProvider(studentId));

    return familyAsync.when(
      data: (family) {
        return Column(
          children: [
            if (family.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No family members added',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: family.length,
                  itemBuilder: (context, index) {
                    final member = family[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (member['name'] as String? ?? '?')[0].toUpperCase(),
                          ),
                        ),
                        title: Text(member['name'] as String? ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Relation: ${member['relation'] as String? ?? 'N/A'}',
                            ),
                            if (member['contact'] != null)
                              Text('Contact: ${member['contact']}'),
                            if (member['occupation'] != null)
                              Text('Occupation: ${member['occupation']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Family Member'),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => AddFamilyDialog(studentId: studentId),
                  );
                  ref.invalidate(studentFamilyProvider(studentId));
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _EmergencyTab extends ConsumerWidget {
  const _EmergencyTab({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(
      studentEmergencyContactsProvider(studentId),
    );

    return contactsAsync.when(
      data: (contacts) {
        return Column(
          children: [
            if (contacts.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No emergency contacts added',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(contact['name'] as String? ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone: ${contact['phone'] as String? ?? 'N/A'}',
                            ),
                            if (contact['relation'] != null)
                              Text('Relation: ${contact['relation']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () {
                            // TODO: Make phone call
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Emergency Contact'),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => AddEmergencyDialog(studentId: studentId),
                  );
                  ref.invalidate(studentEmergencyContactsProvider(studentId));
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
