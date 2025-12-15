import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/user_role.dart';
import '../../application/library_providers.dart';
import '../../domain/book_type.dart';
import '../widgets/digital_resource_item.dart';

class DigitalLibraryTab extends ConsumerStatefulWidget {
  const DigitalLibraryTab({super.key});

  @override
  ConsumerState<DigitalLibraryTab> createState() => _DigitalLibraryTabState();
}

class _DigitalLibraryTabState extends ConsumerState<DigitalLibraryTab> {
  DigitalResourceType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider);
    final isAdmin = authUser?.role == UserRole.admin ||
        authUser?.role == UserRole.principal;
    final isTeacher = authUser?.role == UserRole.teacher;
    final canUpload = isAdmin || isTeacher;

    final resourcesAsync = ref.watch(digitalResourcesProvider);

    return Column(
      children: [
        if (canUpload)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DigitalResourceType?>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Filter by Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<DigitalResourceType?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...DigitalResourceType.values.map(
                        (type) => DropdownMenuItem<DigitalResourceType?>(
                          value: type,
                          child: Text(type.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _uploadResource,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Resource'),
                ),
              ],
            ),
          ),
        Expanded(
          child: resourcesAsync.when(
            data: (resources) {
              final filtered = _selectedType == null
                  ? resources
                  : resources
                      .where((r) => r.resourceType == _selectedType)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No digital resources found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return DigitalResourceItem(resource: filtered[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading resources',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadResource() async {
    // TODO: Implement file upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload feature coming soon')),
    );
  }
}

