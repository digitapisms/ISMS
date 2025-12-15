import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/messaging_providers.dart';
import '../widgets/circular_list_item.dart';
import '../dialogs/circular_form_dialog.dart';

class CircularsTab extends ConsumerWidget {
  const CircularsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circularsAsync = ref.watch(circularsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const CircularFormDialog(),
          );
          ref.invalidate(circularsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: circularsAsync.when(
        data: (circulars) {
          if (circulars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No circulars yet',
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
            itemCount: circulars.length,
            itemBuilder: (context, index) {
              return CircularListItem(
                circular: circulars[index],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading circulars: $error',
            style: TextStyle(color: Colors.red[600]),
          ),
        ),
      ),
    );
  }
}

