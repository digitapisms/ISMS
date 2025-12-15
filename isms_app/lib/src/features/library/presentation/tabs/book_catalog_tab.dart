import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/user_role.dart';
import '../../application/library_providers.dart';
import '../../domain/book_type.dart';
import '../dialogs/book_form_dialog.dart';
import '../widgets/book_list_item.dart';

class BookCatalogTab extends ConsumerStatefulWidget {
  const BookCatalogTab({super.key});

  @override
  ConsumerState<BookCatalogTab> createState() => _BookCatalogTabState();
}

class _BookCatalogTabState extends ConsumerState<BookCatalogTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  BookType? _selectedBookType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider);
    final isAdmin = authUser?.role == UserRole.admin ||
        authUser?.role == UserRole.principal;
    final isTeacher = authUser?.role == UserRole.teacher;

    final booksAsync = ref.watch(
      _searchQuery.isEmpty
          ? booksProvider
          : searchBooksProvider(_searchQuery),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search books by title, author, or ISBN...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<BookType?>(
                      value: _selectedBookType,
                      decoration: InputDecoration(
                        labelText: 'Book Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<BookType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...BookType.values.map(
                          (type) => DropdownMenuItem<BookType?>(
                            value: type,
                            child: Text(type.displayName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedBookType = value);
                      },
                    ),
                  ),
                  if (isAdmin || isTeacher) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const BookFormDialog(),
                        );
                        if (result == true) {
                          ref.invalidate(booksProvider);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Book'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: booksAsync.when(
            data: (books) {
              final filteredBooks = _selectedBookType == null
                  ? books
                  : books.where((b) => b.bookType == _selectedBookType).toList();

              if (filteredBooks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No books found'
                            : 'No books match your search',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  return BookListItem(
                    book: filteredBooks[index],
                    onTap: () {
                      // TODO: Navigate to book details
                    },
                  );
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
                    'Error loading books',
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
}

