import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../domain/book.dart';
import '../../domain/book_type.dart';
import '../../../school_registration/application/school_providers.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  const BookFormDialog({this.book, super.key});

  final Book? book;

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _isbnController = TextEditingController();
  final _editionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shelfLocationController = TextEditingController();
  final _priceController = TextEditingController();

  BookType _selectedBookType = BookType.physical;
  int? _publicationYear;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author ?? '';
      _publisherController.text = book.publisher ?? '';
      _isbnController.text = book.isbn ?? '';
      _editionController.text = book.edition ?? '';
      _descriptionController.text = book.description ?? '';
      _shelfLocationController.text = book.shelfLocation ?? '';
      _priceController.text = book.price?.toString() ?? '';
      _selectedBookType = book.bookType;
      _publicationYear = book.publicationYear;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    _editionController.dispose();
    _descriptionController.dispose();
    _shelfLocationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(libraryRepositoryProvider);
      final school = ref.read(currentSchoolProvider);
      if (school == null) {
        throw Exception('School context required');
      }

      final book = Book(
        id: widget.book?.id ?? 0,
        schoolId: school.id,
        title: _titleController.text.trim(),
        author: _authorController.text.trim().isEmpty
            ? null
            : _authorController.text.trim(),
        publisher: _publisherController.text.trim().isEmpty
            ? null
            : _publisherController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty
            ? null
            : _isbnController.text.trim(),
        edition: _editionController.text.trim().isEmpty
            ? null
            : _editionController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        shelfLocation: _shelfLocationController.text.trim().isEmpty
            ? null
            : _shelfLocationController.text.trim(),
        price: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        publicationYear: _publicationYear,
        bookType: _selectedBookType,
      );

      if (widget.book == null) {
        await repo.createBook(book);
      } else {
        await repo.updateBook(book);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.book == null
                  ? 'Book added successfully'
                  : 'Book updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(widget.book == null ? 'Add Book' : 'Edit Book'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _authorController,
                              decoration: const InputDecoration(
                                labelText: 'Author',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _publisherController,
                              decoration: const InputDecoration(
                                labelText: 'Publisher',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _isbnController,
                              decoration: const InputDecoration(
                                labelText: 'ISBN',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<BookType>(
                              value: _selectedBookType,
                              decoration: const InputDecoration(
                                labelText: 'Book Type',
                                border: OutlineInputBorder(),
                              ),
                              items: BookType.values.map((type) {
                                return DropdownMenuItem<BookType>(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedBookType = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _editionController,
                              decoration: const InputDecoration(
                                labelText: 'Edition',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: TextEditingController(
                                text: _publicationYear?.toString() ?? '',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Publication Year',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _publicationYear = int.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shelfLocationController,
                              decoration: const InputDecoration(
                                labelText: 'Shelf Location',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

