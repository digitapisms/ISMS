import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/ptm_providers.dart';
import '../../domain/ptm_meeting.dart';
import '../../domain/ptm_note.dart';
import '../dialogs/note_form_dialog.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final PTMMeeting meeting;

  const MeetingDetailScreen({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(ptmNotesProvider(meeting.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'PTM Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple[700]!,
                      Colors.indigo[700]!,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.handshake,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Date & Time',
                    content: Text(
                      DateFormat('EEEE, MMMM d, y • h:mm a')
                          .format(meeting.meetingDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (meeting.location != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on,
                      title: 'Location',
                      content: Text(
                        meeting.location!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  if (meeting.agenda != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.notes,
                      title: 'Agenda',
                      content: Text(
                        meeting.agenda!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.note,
                    title: 'Meeting Notes',
                    content: notesAsync.when(
                      data: (notes) {
                        if (notes.isEmpty) {
                          return const Text('No notes yet');
                        }
                        return Column(
                          children: notes.map((note) {
                            return ListTile(
                              title: Text(note.noteType.displayName),
                              subtitle: Text(note.content),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => NoteFormDialog(
                            meetingId: meeting.id,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Note'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

