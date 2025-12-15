import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/visitor_providers.dart';
import '../widgets/visit_list_item.dart';

class VisitsTab extends ConsumerWidget {
  const VisitsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(visitsProvider);

    return visitsAsync.when(
      data: (visits) {
        if (visits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No visit history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
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
            return VisitListItem(
              visit: visits[index],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

