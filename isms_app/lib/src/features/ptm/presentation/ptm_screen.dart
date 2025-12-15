import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/user_role.dart';
import '../application/ptm_providers.dart';
import 'widgets/meeting_card.dart';
import 'dialogs/meeting_form_dialog.dart';
import 'screens/meeting_detail_screen.dart';

class PTMScreen extends ConsumerStatefulWidget {
  const PTMScreen({super.key});

  @override
  ConsumerState<PTMScreen> createState() => _PTMScreenState();
}

class _PTMScreenState extends ConsumerState<PTMScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final meetingsAsync = ref.watch(ptmMeetingsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isAdmin = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.principal ||
        currentUser?.role == UserRole.teacher;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'PTM Management',
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
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Selected Date'),
                      subtitle: Text(DateFormat('MMM d, y').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: meetingsAsync.when(
                data: (meetings) {
                  final dayMeetings = meetings.where((m) {
                    return m.meetingDate.year == _selectedDate.year &&
                        m.meetingDate.month == _selectedDate.month &&
                        m.meetingDate.day == _selectedDate.day;
                  }).toList();

                  if (dayMeetings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No meetings scheduled',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayMeetings.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MeetingCard(
                          meeting: dayMeetings[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeetingDetailScreen(
                                  meeting: dayMeetings[index],
                                ),
                              ),
                            );
                          },
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
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const MeetingFormDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Schedule Meeting'),
            )
          : null,
    );
  }
}

