import 'package:flutter/material.dart';

import 'tabs/announcements_tab.dart';
import 'tabs/circulars_tab.dart';
import 'tabs/conversations_tab.dart';
import 'tabs/templates_tab.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Communication & Messaging'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Messages'),
            Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
            Tab(icon: Icon(Icons.description), text: 'Circulars'),
            Tab(icon: Icon(Icons.description_outlined), text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ConversationsTab(),
          AnnouncementsTab(),
          CircularsTab(),
          TemplatesTab(),
        ],
      ),
    );
  }
}

