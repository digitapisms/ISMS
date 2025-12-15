import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/library_providers.dart';
import '../../domain/book.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../student_management/domain/student.dart';

class IssueBookDialog extends ConsumerStatefulWidget {
  const IssueBookDialog({super.key});

  @override
  ConsumerState<IssueBookDialog> createState() => _IssueBookDialogState();
}

class _IssueBookDialogState extends ConsumerState<IssueBookDialog> {
  final _formKey = GlobalKey<FormState>();
  Book? _selectedBook;
  Student? _selectedStudent;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Issue Book'),
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
                      booksAsync.when(
                        data: (books) {
                          final availableBooks =
                              books.where((b) => b.isAvailable).toList();
                          return DropdownButtonFormField<Book>(
                            decoration: const InputDecoration(
                              labelText: 'Select Book *',
                              border: OutlineInputBorder(),
                            ),
                            items: availableBooks.map((book) {
                              return DropdownMenuItem<Book>(
                                value: book,
                                child: Text(
                                  '${book.title}${book.author != null ? ' - ${book.author}' : ''} (${book.availableCopies} available)',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedBook = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a book';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error: $error'),
                      ),
                      const SizedBox(height: 16),
                      studentsAsync.when(
                        data: (students) {
                          return DropdownButtonFormField<Student>(
                            decoration: const InputDecoration(
                              labelText: 'Select Student *',
                              border: OutlineInputBorder(),
                            ),
                            items: students.map((student) {
                              return DropdownMenuItem<Student>(
                                value: student,
                                child: Text(
                                  '${student.fullName} (${student.admissionNo})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedStudent = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a student';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error: $error'),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 14)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _dueDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : 'Select due date',
                          ),
                        ),
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
                      onPressed: _isLoading ? null : _issueBook,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Issue Book'),
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

  Future<void> _issueBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBook == null || _selectedStudent == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.issueBook(
        bookId: _selectedBook!.id,
        studentId: _selectedStudent!.id,
        dueDate: _dueDate!,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book issued successfully')),
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
}

