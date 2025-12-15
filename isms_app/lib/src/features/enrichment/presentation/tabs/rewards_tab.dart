import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/reward.dart';
import '../../../student_management/application/student_providers.dart';

class RewardsTab extends ConsumerWidget {
  const RewardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudentAsync = ref.watch(currentStudentProvider);
    final rewardsAsync = ref.watch(activityRewardsProvider);

    return currentStudentAsync.when(
      data: (currentStudent) {
        final currentStudentId = currentStudent?.id;
        final pointsAsync = currentStudentId != null
            ? ref.watch(studentPointsProvider(currentStudentId))
            : null;

        return Column(
          children: [
            // Points Summary Card
            if (pointsAsync != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: pointsAsync.when(
                  data: (points) => Column(
                    children: [
                      Text(
                        'Your Points',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        points.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  loading: () =>
                      const CircularProgressIndicator(color: Colors.white),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            // Rewards List
            Expanded(
              child: rewardsAsync.when(
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rewards available',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rewards will appear here when added',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      return _RewardCard(
                        reward: reward,
                        currentStudentId: currentStudentId,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load rewards',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(activityRewardsProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
              'Failed to load student data',
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
}

class _RewardCard extends ConsumerWidget {
  final ActivityReward reward;
  final String? currentStudentId;

  const _RewardCard({required this.reward, this.currentStudentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = currentStudentId != null
        ? ref.watch(studentPointsProvider(currentStudentId!))
        : null;
    final canRedeem =
        pointsAsync?.value != null &&
        pointsAsync!.value! >= reward.pointsRequired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (reward.iconUrl != null)
              Image.network(
                reward.iconUrl!,
                width: 64,
                height: 64,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              )
            else
              Icon(
                Icons.emoji_events,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (reward.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      reward.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.pointsRequired} points',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (currentStudentId != null)
              ElevatedButton(
                onPressed: canRedeem
                    ? () async {
                        try {
                          final repo = ref.read(enrichmentRepositoryProvider);
                          await repo.redeemReward(
                            studentId:
                                null, // Will auto-detect from current user
                            rewardId: reward.id,
                            pointsSpent: reward.pointsRequired,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully redeemed ${reward.name}!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Refresh rewards and points
                            ref.invalidate(activityRewardsProvider);
                            ref.invalidate(
                              studentPointsProvider(currentStudentId!),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                child: const Text('Redeem'),
              ),
          ],
        ),
      ),
    );
  }
}
