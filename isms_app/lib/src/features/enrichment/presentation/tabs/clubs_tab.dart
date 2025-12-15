import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/club.dart';
import '../screens/club_detail_screen.dart';
import '../widgets/create_club_dialog.dart';

class ClubsTab extends ConsumerWidget {
  const ClubsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider('active'));

    return clubsAsync.when(
      data: (clubs) {
        if (clubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No clubs available',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clubs will appear here when created',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Clubs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CreateClubDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Club'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: clubs.length,
                itemBuilder: (context, index) {
                  final club = clubs[index];
                  return _ClubCard(club: club);
                },
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
              'Failed to load clubs',
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
                ref.invalidate(clubsProvider('active'));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubCard extends ConsumerWidget {
  final Club club;

  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ClubDetailScreen(clubId: club.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(club.status.name.toUpperCase()),
                    backgroundColor: club.status == ClubStatus.active
                        ? Colors.green[100]
                        : Colors.grey[100],
                  ),
                ],
              ),
              if (club.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  club.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (club.meetingSchedule != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      club.meetingSchedule!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (club.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: club.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
