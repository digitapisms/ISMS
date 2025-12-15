import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/transport_providers.dart';
import '../../domain/transport_type.dart';

class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final attendanceAsync = ref.watch(transportAttendanceProvider(today));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transport Attendance',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance marking coming soon')),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Attendance'),
              ),
            ],
          ),
        ),
        Expanded(
          child: attendanceAsync.when(
            data: (attendance) {
              if (attendance.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records for today',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: attendance.length,
                itemBuilder: (context, index) {
                  final record = attendance[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus),
                      title: Text('Trip: ${record.tripType.displayName}'),
                      subtitle: Text(
                        'Pickup: ${record.pickupStatus.displayName} | Dropoff: ${record.dropoffStatus.displayName}',
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

