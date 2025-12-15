import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/visitor_providers.dart';
import '../../domain/visitor_type.dart';
import '../dialogs/check_in_dialog.dart';

class CheckInTab extends ConsumerWidget {
  const CheckInTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVisitsAsync = ref.watch(activeVisitsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Check-In',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Register and check in visitors',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CheckInDialog(),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('New Check-In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: activeVisitsAsync.when(
            data: (visits) {
              if (visits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active visits',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All visitors have checked out',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: visits.length,
                itemBuilder: (context, index) {
                  final visit = visits[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          Icons.person,
                          color: Colors.green[800],
                        ),
                      ),
                      title: Text(visit.hostName ?? 'Unknown Host'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(visit.visitPurpose.displayName),
                          if (visit.checkInTime != null)
                            Text(
                              'Checked in: ${visit.checkInTime!.hour}:${visit.checkInTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final repo = ref.read(visitorRepositoryProvider);
                          try {
                            await repo.checkOut(visit.id);
                            ref.invalidate(activeVisitsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Visitor checked out successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Check Out'),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

