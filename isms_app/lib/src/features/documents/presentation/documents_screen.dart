import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../application/documents_providers.dart';
import 'widgets/document_card.dart';
import 'dialogs/upload_document_dialog.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String? _selectedDocumentType;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isAdmin = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.principal ||
        currentUser?.role == UserRole.teacher ||
        currentUser?.role == UserRole.staff;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Documents',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search documents...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                ref.invalidate(documentsProvider);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      ref.invalidate(documentsProvider);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDocumentType,
                    decoration: InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...['academic', 'administrative', 'student_records', 'reports']
                          .map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type.replaceAll('_', ' ').toUpperCase()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedDocumentType = value);
                      ref.invalidate(documentsProvider);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: documentsAsync.when(
                data: (documents) {
                  if (documents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No documents found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      return DocumentCard(
                        document: documents[index],
                        onTap: () {
                          // TODO: Open document viewer
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const UploadDocumentDialog(),
                );
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Document'),
            )
          : null,
    );
  }
}

