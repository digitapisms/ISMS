import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/leaderboards_screen.dart';
import 'tabs/clubs_tab.dart';
import 'tabs/games_tab.dart';
import 'tabs/quizzes_tab.dart';
import 'tabs/rewards_tab.dart';

class EnrichmentScreen extends ConsumerStatefulWidget {
  const EnrichmentScreen({super.key});

  @override
  ConsumerState<EnrichmentScreen> createState() => _EnrichmentScreenState();
}

class _EnrichmentScreenState extends ConsumerState<EnrichmentScreen>
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
        title: const Text('Enrichment & Play'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Quizzes'),
            Tab(icon: Icon(Icons.sports_esports_outlined), text: 'Games'),
            Tab(icon: Icon(Icons.group_outlined), text: 'Clubs'),
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Rewards'),
            Tab(icon: Icon(Icons.leaderboard_outlined), text: 'Leaderboards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          QuizzesTab(),
          GamesTab(),
          ClubsTab(),
          RewardsTab(),
          LeaderboardsScreen(),
        ],
      ),
    );
  }
}
