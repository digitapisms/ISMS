import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../../student_management/application/student_providers.dart';
import '../../../student_management/domain/student.dart';

class LeaderboardsScreen extends ConsumerStatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  ConsumerState<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends ConsumerState<LeaderboardsScreen>
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
        title: const Text('Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.stars), text: 'Points'),
            Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
            Tab(icon: Icon(Icons.sports_esports), text: 'Games'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PointsLeaderboardTab(),
          QuizLeaderboardTab(),
          GameLeaderboardTab(),
        ],
      ),
    );
  }
}

class PointsLeaderboardTab extends ConsumerWidget {
  const PointsLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final currentStudentAsync = ref.watch(currentStudentProvider);

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No students found'));
        }

        // Fetch points for all students
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(
            students.map((student) async {
              try {
                final points = await ref.read(
                  studentPointsProvider(student.id).future,
                );
                return {'student': student, 'points': points};
              } catch (e) {
                return {'student': student, 'points': 0.0};
              }
            }),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final leaderboard = snapshot.data!
              ..sort(
                (a, b) =>
                    (b['points'] as double).compareTo(a['points'] as double),
              );

            final currentStudent = currentStudentAsync.value;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final student = entry['student'] as Student;
                final points = entry['points'] as double;
                final isCurrentUser = currentStudent?.id == student.id;
                final rank = index + 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: _buildRankBadge(rank),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.fullName,
                            style: TextStyle(
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('${student.admissionNo}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          points.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
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
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load leaderboard',
              style: Theme.of(context).textTheme.titleMedium,
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
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = Colors.amber;
      icon = Icons.looks_one;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
      icon = Icons.looks_two;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!;
      icon = Icons.looks_3;
    } else {
      badgeColor = Colors.grey[300]!;
    }

    return CircleAvatar(
      backgroundColor: badgeColor,
      child: icon != null
          ? Icon(icon, color: Colors.white)
          : Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class QuizLeaderboardTab extends ConsumerWidget {
  const QuizLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(enrichmentRepositoryProvider);
    final leaderboardAsync = FutureProvider<List<Map<String, dynamic>>>((
      ref,
    ) async {
      return repo.getQuizLeaderboard(limit: 50);
    });

    return Consumer(
      builder: (context, ref, child) {
        final leaderboard = ref.watch(leaderboardAsync);

        return leaderboard.when(
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No quiz attempts yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students need to complete quizzes to appear on the leaderboard',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final currentStudent = ref.watch(currentStudentProvider).value;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data[index];
                final student = entry['student'] as Map<String, dynamic>?;
                final avgPercentage =
                    entry['average_percentage'] as double? ?? 0.0;
                final attempts = entry['total_attempts'] as int? ?? 0;
                final studentId = entry['student_id'] as String?;
                final isCurrentUser = currentStudent?.id == studentId;
                final rank = index + 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: _buildRankBadge(rank),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            student?['full_name'] as String? ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${student?['admission_no'] ?? 'N/A'} • $attempts attempt${attempts != 1 ? 's' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${avgPercentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Average',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load quiz leaderboard',
                  style: Theme.of(context).textTheme.titleMedium,
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
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = Colors.amber;
      icon = Icons.looks_one;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
      icon = Icons.looks_two;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!;
      icon = Icons.looks_3;
    } else {
      badgeColor = Colors.grey[300]!;
    }

    return CircleAvatar(
      backgroundColor: badgeColor,
      child: icon != null
          ? Icon(icon, color: Colors.white)
          : Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class GameLeaderboardTab extends ConsumerWidget {
  const GameLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(enrichmentRepositoryProvider);
    final leaderboardAsync = FutureProvider<List<Map<String, dynamic>>>((
      ref,
    ) async {
      return repo.getGameLeaderboard(limit: 50);
    });

    return Consumer(
      builder: (context, ref, child) {
        final leaderboard = ref.watch(leaderboardAsync);

        return leaderboard.when(
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_esports_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No game sessions yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students need to play games to appear on the leaderboard',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final currentStudent = ref.watch(currentStudentProvider).value;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data[index];
                final student = entry['student'] as Map<String, dynamic>?;
                final highestScore = entry['highest_score'] as int? ?? 0;
                final totalGames = entry['total_games'] as int? ?? 0;
                final studentId = entry['student_id'] as String?;
                final isCurrentUser = currentStudent?.id == studentId;
                final rank = index + 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: _buildRankBadge(rank),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            student?['full_name'] as String? ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${student?['admission_no'] ?? 'N/A'} • $totalGames game${totalGames != 1 ? 's' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              highestScore.toString(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          'Best Score',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load game leaderboard',
                  style: Theme.of(context).textTheme.titleMedium,
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
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = Colors.amber;
      icon = Icons.looks_one;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
      icon = Icons.looks_two;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!;
      icon = Icons.looks_3;
    } else {
      badgeColor = Colors.grey[300]!;
    }

    return CircleAvatar(
      backgroundColor: badgeColor,
      child: icon != null
          ? Icon(icon, color: Colors.white)
          : Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
