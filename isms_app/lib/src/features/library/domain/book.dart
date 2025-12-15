import 'package:equatable/equatable.dart';

import 'book_type.dart';

class Book extends Equatable {
  const Book({
    required this.id,
    required this.schoolId,
    required this.title,
    this.isbn,
    this.author,
    this.publisher,
    this.publicationYear,
    this.edition,
    this.language = 'english',
    this.categoryId,
    this.bookType = BookType.physical,
    this.description,
    this.coverImageUrl,
    this.totalCopies = 0,
    this.availableCopies = 0,
    this.price,
    this.shelfLocation,
    this.tags = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String schoolId;
  final String? isbn;
  final String title;
  final String? author;
  final String? publisher;
  final int? publicationYear;
  final String? edition;
  final String language;
  final int? categoryId;
  final BookType bookType;
  final String? description;
  final String? coverImageUrl;
  final int totalCopies;
  final int availableCopies;
  final double? price;
  final String? shelfLocation;
  final List<String> tags;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Book.fromMap(Map<String, dynamic> map) {
    final tagsData = map['tags'];
    return Book(
      id: map['id'] as int,
      schoolId: map['school_id'] as String,
      isbn: map['isbn'] as String?,
      title: map['title'] as String,
      author: map['author'] as String?,
      publisher: map['publisher'] as String?,
      publicationYear: map['publication_year'] as int?,
      edition: map['edition'] as String?,
      language: map['language'] as String? ?? 'english',
      categoryId: map['category_id'] as int?,
      bookType: BookTypeX.fromDb(map['book_type'] as String? ?? 'physical'),
      description: map['description'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      totalCopies: (map['total_copies'] as int?) ?? 0,
      availableCopies: (map['available_copies'] as int?) ?? 0,
      price: (map['price'] as num?)?.toDouble(),
      shelfLocation: map['shelf_location'] as String?,
      tags: tagsData != null
          ? (tagsData as List).map((e) => e.toString()).toList()
          : [],
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'isbn': isbn,
      'title': title,
      'author': author,
      'publisher': publisher,
      'publication_year': publicationYear,
      'edition': edition,
      'language': language,
      'category_id': categoryId,
      'book_type': bookType.dbValue,
      'description': description,
      'cover_image_url': coverImageUrl,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'price': price,
      'shelf_location': shelfLocation,
      'tags': tags,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isAvailable => availableCopies > 0;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        isbn,
        title,
        author,
        publisher,
        publicationYear,
        edition,
        language,
        categoryId,
        bookType,
        description,
        coverImageUrl,
        totalCopies,
        availableCopies,
        price,
        shelfLocation,
        tags,
        isActive,
        createdAt,
        updatedAt,
      ];
}

