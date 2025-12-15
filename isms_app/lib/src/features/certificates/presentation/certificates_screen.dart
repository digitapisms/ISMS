import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs/templates_tab.dart';
import 'tabs/certificates_tab.dart';
import 'tabs/generate_tab.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Certificate Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Templates'),
            Tab(icon: Icon(Icons.add_circle), text: 'Generate'),
            Tab(icon: Icon(Icons.folder), text: 'Certificates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TemplatesTab(),
          GenerateTab(),
          CertificatesTab(),
        ],
      ),
    );
  }
}

