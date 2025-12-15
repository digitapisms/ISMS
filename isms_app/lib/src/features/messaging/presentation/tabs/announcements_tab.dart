import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/messaging_providers.dart';
import '../widgets/announcement_list_item.dart';
import '../dialogs/announcement_form_dialog.dart';

class AnnouncementsTab extends ConsumerWidget {
  const AnnouncementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AnnouncementFormDialog(),
          );
          ref.invalidate(announcementsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
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
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return AnnouncementListItem(
                announcement: announcements[index],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading announcements: $error',
            style: TextStyle(color: Colors.red[600]),
          ),
        ),
      ),
    );
  }
}

