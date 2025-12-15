import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/book_catalog_tab.dart';
import 'tabs/digital_library_tab.dart';
import 'tabs/fines_tab.dart';
import 'tabs/issues_returns_tab.dart';
import 'tabs/learning_analytics_tab.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Catalog'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Issues & Returns'),
            Tab(icon: Icon(Icons.library_books), text: 'Digital Library'),
            Tab(icon: Icon(Icons.money), text: 'Fines'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BookCatalogTab(),
          IssuesReturnsTab(),
          DigitalLibraryTab(),
          FinesTab(),
          LearningAnalyticsTab(),
        ],
      ),
    );
  }
}
