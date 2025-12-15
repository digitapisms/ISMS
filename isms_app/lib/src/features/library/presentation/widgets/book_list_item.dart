import 'package:flutter/material.dart';

import '../../domain/book.dart';
import '../../domain/book_type.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (book.coverImageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.coverImageUrl!,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.book, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ] else ...[
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, size: 40),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'By ${book.author}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                    if (book.publisher != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.publisher!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(book.bookType.displayName),
                          backgroundColor: _getTypeColor(book.bookType)
                              .withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getTypeColor(book.bookType),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (book.isbn != null)
                          Chip(
                            label: Text('ISBN: ${book.isbn}'),
                            backgroundColor: Colors.grey[200],
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.library_books, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Available: ${book.availableCopies}/${book.totalCopies}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        if (book.shelfLocation != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            book.shelfLocation!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
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

  Color _getTypeColor(BookType type) {
    switch (type) {
      case BookType.physical:
        return Colors.blue;
      case BookType.digital:
        return Colors.purple;
      case BookType.both:
        return Colors.teal;
    }
  }
}

