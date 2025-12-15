import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/enrichment_providers.dart';
import '../../domain/club.dart';

class ClubDetailScreen extends ConsumerWidget {
  final String clubId;

  const ClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(clubProvider(clubId));
    final membersAsync = ref.watch(clubMembersProvider(clubId));
    final eventsAsync = ref.watch(clubEventsProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Club Details')),
      body: clubAsync.when(
        data: (club) {
          if (club == null) {
            return const Center(child: Text('Club not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (club.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    club.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (club.meetingSchedule != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        club.meetingSchedule!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if (club.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: club.tags.map((tag) {
                      return Chip(label: Text(tag));
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final currentUserIdAsync = ref.watch(
                          currentUserIdProvider,
                        );
                        final currentUserId = currentUserIdAsync.value;
                        final isMember =
                            currentUserId != null &&
                            (membersAsync.value?.any(
                                  (m) => m.userId == currentUserId,
                                ) ??
                                false);

                        if (isMember) {
                          return OutlinedButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Leave Club'),
                                  content: const Text(
                                    'Are you sure you want to leave this club?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Leave'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && context.mounted) {
                                try {
                                  final repo = ref.read(
                                    enrichmentRepositoryProvider,
                                  );
                                  await repo.leaveClub(clubId: clubId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('You have left the club'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Refresh members and club
                                    ref.invalidate(clubMembersProvider(clubId));
                                    ref.invalidate(clubProvider(clubId));
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
                            },
                            child: const Text('Leave Club'),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () async {
                              try {
                                final repo = ref.read(
                                  enrichmentRepositoryProvider,
                                );
                                await repo.joinClub(
                                  clubId: clubId,
                                  userId:
                                      null, // Will auto-detect from current user
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Join request submitted!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refresh members
                                  ref.invalidate(clubMembersProvider(clubId));
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
                            },
                            child: const Text('Join Club'),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                membersAsync.when(
                  data: (members) {
                    if (members.isEmpty) {
                      return const Text('No members yet');
                    }
                    return Column(
                      children: members.map((member) {
                        return ListTile(
                          title: Text('Member ${member.id.substring(0, 8)}'),
                          subtitle: Text('Status: ${member.status.name}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(member.role.name),
                              if (member.status == ClubMemberStatus.pending)
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check,
                                            size: 20,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Approve'),
                                        ],
                                      ),
                                      onTap: () async {
                                        Future.delayed(Duration.zero, () async {
                                          try {
                                            final repo = ref.read(
                                              enrichmentRepositoryProvider,
                                            );
                                            await repo.updateClubMemberStatus(
                                              memberId: member.id,
                                              status: 'approved',
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Member approved',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              ref.invalidate(
                                                clubMembersProvider(clubId),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        });
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Reject'),
                                        ],
                                      ),
                                      onTap: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Reject Member'),
                                            content: const Text(
                                              'Are you sure you want to reject this member?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Reject'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true &&
                                            context.mounted) {
                                          try {
                                            final repo = ref.read(
                                              enrichmentRepositoryProvider,
                                            );
                                            await repo.updateClubMemberStatus(
                                              memberId: member.id,
                                              status: 'rejected',
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Member rejected',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                              ref.invalidate(
                                                clubMembersProvider(clubId),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Upcoming Events',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                eventsAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const Text('No upcoming events');
                    }
                    return Column(
                      children: events.map((event) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(event.title),
                            subtitle: Text(
                              DateFormat(
                                'MMM d, y • h:mm a',
                              ).format(event.startTime),
                            ),
                            trailing: Icon(
                              Icons.event,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
              ],
            ),
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
                'Failed to load club',
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
      ),
    );
  }
}
