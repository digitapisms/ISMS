import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/visitor_providers.dart';
import '../widgets/visitor_list_item.dart';

class VisitorsTab extends ConsumerWidget {
  const VisitorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitorsAsync = ref.watch(visitorsProvider);

    return visitorsAsync.when(
      data: (visitors) {
        if (visitors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No visitors registered yet',
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
          itemCount: visitors.length,
          itemBuilder: (context, index) {
            return VisitorListItem(
              visitor: visitors[index],
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

