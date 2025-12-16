import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/online_class_providers.dart';
import '../domain/online_class_platform.dart';
import 'tabs/online_classes_tab.dart';
import 'tabs/upcoming_sessions_tab.dart';
import 'tabs/session_history_tab.dart';

/// Main Online Classes Screen for Institution Management
class OnlineClassesScreen extends ConsumerStatefulWidget {
  const OnlineClassesScreen({super.key});

  @override
  ConsumerState<OnlineClassesScreen> createState() =>
      _OnlineClassesScreenState();
}

class _OnlineClassesScreenState extends ConsumerState<OnlineClassesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.video_library_outlined),
                text: 'Online Classes',
              ),
              Tab(
                icon: Icon(Icons.access_time_outlined),
                text: 'Upcoming Sessions',
              ),
              Tab(icon: Icon(Icons.history_outlined), text: 'Session History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                OnlineClassesTab(),
                UpcomingSessionsTab(),
                SessionHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show create online class dialog
          _showCreateClassDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final platformOptions = OnlineClassPlatform.values;
    final now = DateTime.now();
    final defaultStartTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 1,
    );
    final defaultEndTime = defaultStartTime.add(const Duration(hours: 1));

    String title = '';
    String description = '';
    OnlineClassPlatform selectedPlatform = OnlineClassPlatform.zoom;
    DateTime selectedStartTime = defaultStartTime;
    DateTime selectedEndTime = defaultEndTime;
    int expectedParticipants = 20;
    bool recordSession = false;
    bool breakoutRoomsEnabled = false;
    bool waitingRoomEnabled = true;
    bool chatEnabled = true;
    bool screenSharingEnabled = true;
    bool handRaiseEnabled = true;
    bool pollingEnabled = false;
    bool qaEnabled = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Online Class'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Class Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<OnlineClassPlatform>(
                    initialValue: selectedPlatform,
                    decoration: const InputDecoration(
                      labelText: 'Platform',
                      border: OutlineInputBorder(),
                    ),
                    items: platformOptions.map((platform) {
                      return DropdownMenuItem(
                        value: platform,
                        child: Text(platform.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPlatform = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time'),
                            TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    selectedStartTime,
                                  ),
                                );
                                if (time != null) {
                                  setState(() {
                                    selectedStartTime = DateTime(
                                      selectedStartTime.year,
                                      selectedStartTime.month,
                                      selectedStartTime.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              },
                              child: Text(
                                '${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time'),
                            TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    selectedEndTime,
                                  ),
                                );
                                if (time != null) {
                                  setState(() {
                                    selectedEndTime = DateTime(
                                      selectedEndTime.year,
                                      selectedEndTime.month,
                                      selectedEndTime.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              },
                              child: Text(
                                '${selectedEndTime.hour.toString().padLeft(2, '0')}:${selectedEndTime.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Expected Participants',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        expectedParticipants = int.parse(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Record Session'),
                    value: recordSession,
                    onChanged: (value) => setState(() => recordSession = value),
                  ),
                  SwitchListTile(
                    title: const Text('Breakout Rooms'),
                    value: breakoutRoomsEnabled,
                    onChanged: (value) =>
                        setState(() => breakoutRoomsEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Waiting Room'),
                    value: waitingRoomEnabled,
                    onChanged: (value) =>
                        setState(() => waitingRoomEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Chat'),
                    value: chatEnabled,
                    onChanged: (value) => setState(() => chatEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Screen Sharing'),
                    value: screenSharingEnabled,
                    onChanged: (value) =>
                        setState(() => screenSharingEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Hand Raise'),
                    value: handRaiseEnabled,
                    onChanged: (value) =>
                        setState(() => handRaiseEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Polling'),
                    value: pollingEnabled,
                    onChanged: (value) =>
                        setState(() => pollingEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Q&A Session'),
                    value: qaEnabled,
                    onChanged: (value) => setState(() => qaEnabled = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a class title'),
                      ),
                    );
                    return;
                  }

                  final duration = selectedEndTime.difference(
                    selectedStartTime,
                  );
                  if (duration.inMinutes < 15) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Class duration must be at least 15 minutes',
                        ),
                      ),
                    );
                    return;
                  }

                  // Create the online class using the provider
                  ref
                      .read(onlineClassCreatorProvider.notifier)
                      .createOnlineClass(
                        title: title,
                        description: description,
                        platform: selectedPlatform,
                        duration: duration,
                        scheduledStart: selectedStartTime,
                        scheduledEnd: selectedEndTime,
                        expectedParticipants: expectedParticipants,
                        recordSession: recordSession,
                        breakoutRoomsEnabled: breakoutRoomsEnabled,
                        waitingRoomEnabled: waitingRoomEnabled,
                        chatEnabled: chatEnabled,
                        screenSharingEnabled: screenSharingEnabled,
                        handRaiseEnabled: handRaiseEnabled,
                        pollingEnabled: pollingEnabled,
                        qaEnabled: qaEnabled,
                      );

                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
