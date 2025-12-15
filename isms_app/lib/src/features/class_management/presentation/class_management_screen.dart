import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/class_providers.dart';
import '../domain/class_model.dart';
import 'class_form_dialog.dart';
import 'section_management_screen.dart';

class ClassManagementScreen extends ConsumerStatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  ConsumerState<ClassManagementScreen> createState() =>
      _ClassManagementScreenState();
}

class _ClassManagementScreenState extends ConsumerState<ClassManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class & Section Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddClassDialog(context),
            tooltip: 'Add Class',
          ),
        ],
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No classes yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first class to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Class'),
                    onPressed: () => _showAddClassDialog(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classModel = classes[index];
              return _ClassCard(
                classModel: classModel,
                onEdit: () => _showEditClassDialog(context, classModel),
                onDelete: () => _confirmDeleteClass(context, classModel),
                onManageSections: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SectionManagementScreen(classId: classModel.id),
                    ),
                  );
                },
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
                  'Error loading classes',
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
                  onPressed: () => ref.invalidate(classesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const ClassFormDialog()).then((
      _,
    ) {
      ref.invalidate(classesProvider);
    });
  }

  void _showEditClassDialog(BuildContext context, ClassModel classModel) {
    showDialog(
      context: context,
      builder: (_) => ClassFormDialog(classModel: classModel),
    ).then((_) {
      ref.invalidate(classesProvider);
    });
  }

  Future<void> _confirmDeleteClass(
    BuildContext context,
    ClassModel classModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text(
          'Are you sure you want to delete "${classModel.name}"? '
          'This will also delete all sections in this class.',
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
        await repo.deleteClass(classModel.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class deleted successfully')),
          );
        }
        ref.invalidate(classesProvider);
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

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classModel,
    required this.onEdit,
    required this.onDelete,
    required this.onManageSections,
  });

  final ClassModel classModel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageSections;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onManageSections,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              classModel.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (classModel.code != null) ...[
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
                                  classModel.code!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                              ),
                            ],
                            if (!classModel.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
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
                        if (classModel.level != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Level ${classModel.level}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (classModel.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            classModel.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      } else if (value == 'sections') {
                        onManageSections();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'sections',
                        child: ListTile(
                          leading: Icon(Icons.group),
                          title: Text('Manage Sections'),
                          dense: true,
                        ),
                      ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${classModel.sectionCount ?? 0} sections',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  FilledButton.tonal(
                    onPressed: onManageSections,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Manage Sections'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
