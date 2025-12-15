import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/room.dart';
import '../dialogs/room_form_dialog.dart';

/// Tab for managing rooms
class RoomsTab extends ConsumerWidget {
  const RoomsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rooms & Venues',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const RoomFormDialog(),
                  );
                  if (result == true) {
                    ref.invalidate(roomsProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Room'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rooms defined',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add rooms and venues to assign to timetable entries',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            _getRoomIcon(room.roomType),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(room.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${room.roomType.displayName}'),
                            if (room.capacity != null)
                              Text('Capacity: ${room.capacity}'),
                            if (room.buildingName != null)
                              Text('Building: ${room.buildingName}'),
                            if (room.facilities.isNotEmpty)
                              Text(
                                'Facilities: ${room.facilities.join(', ')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (_) => RoomFormDialog(room: room),
                            );
                            if (result == true) {
                              ref.invalidate(roomsProvider);
                            }
                          },
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading rooms',
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
          ),
        ],
      ),
    );
  }

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.classroom:
        return Icons.class_;
      case RoomType.lab:
        return Icons.science;
      case RoomType.library:
        return Icons.library_books;
      case RoomType.hall:
        return Icons.event;
      case RoomType.sports:
        return Icons.sports;
      case RoomType.computerLab:
        return Icons.computer;
    }
  }
}
