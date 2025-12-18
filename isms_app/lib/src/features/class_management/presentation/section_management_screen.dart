import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/class_providers.dart';
import '../domain/section_model.dart';
import 'section_form_dialog.dart';

class SectionManagementScreen extends ConsumerStatefulWidget {
  const SectionManagementScreen({super.key, required this.classId});

  final int classId;

  @override
  ConsumerState<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState
    extends ConsumerState<SectionManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classProvider(widget.classId));
    final sectionsAsync = ref.watch(sectionsProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(
        title: classAsync.when(
          data: (classModel) => Text(
            classModel != null ? 'Sections - ${classModel.name}' : 'Sections',
          ),
          loading: () => const Text('Sections'),
          error: (_, __) => const Text('Sections'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSectionDialog(context),
            tooltip: 'Add Section',
          ),
        ],
      ),
      body: sectionsAsync.when(
        data: (sections) {
          if (sections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sections yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first section for this class',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Section'),
                    onPressed: () => _showAddSectionDialog(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return _SectionCard(
                section: section,
                onEdit: () => _showEditSectionDialog(context, section),
                onDelete: () => _confirmDeleteSection(context, section),
              );
            },
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
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading sections',
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
                  onPressed: () =>
                      ref.invalidate(sectionsProvider(widget.classId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SectionFormDialog(classId: widget.classId),
    ).then((_) {
      ref.invalidate(sectionsProvider(widget.classId));
    });
  }

  void _showEditSectionDialog(BuildContext context, SectionModel section) {
    showDialog(
      context: context,
      builder: (_) =>
          SectionFormDialog(classId: widget.classId, section: section),
    ).then((_) {
      ref.invalidate(sectionsProvider(widget.classId));
    });
  }

  Future<void> _confirmDeleteSection(
    BuildContext context,
    SectionModel section,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section?'),
        content: Text(
          'Are you sure you want to delete "${section.name}"? '
          'This action cannot be undone if students are assigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(classRepositoryProvider);
        await repo.deleteSection(section.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Section deleted successfully')),
          );
        }
        ref.invalidate(sectionsProvider(widget.classId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final SectionModel section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        section.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (section.code != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            section.code!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                      if (!section.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Inactive',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (section.capacity != null) ...[
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Capacity: ${section.capacity}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${section.studentCount ?? 0} students',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (section.capacity != null &&
                          section.studentCount != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${section.capacity! - section.studentCount!} available)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    section.studentCount! >= section.capacity!
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
