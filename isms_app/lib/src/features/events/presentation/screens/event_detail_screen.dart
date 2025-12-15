import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/events_providers.dart';
import '../../domain/event.dart';
import '../../domain/event_type.dart';
import '../dialogs/event_registration_dialog.dart';

class EventDetailScreen extends ConsumerWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationsAsync = ref.watch(eventRegistrationsProvider(event.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
                style: const TextStyle(
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
                      event.eventType.color,
                      event.eventType.color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    event.eventType.icon,
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
                    content: _buildDateTimeInfo(),
                  ),
                  const SizedBox(height: 12),
                  if (event.location != null)
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on,
                      title: 'Location',
                      content: Text(
                        event.location!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (event.description != null)
                    _buildInfoCard(
                      context,
                      icon: Icons.description,
                      title: 'Description',
                      content: Text(
                        event.description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.people,
                    title: 'Registrations',
                    content: registrationsAsync.when(
                      data: (registrations) {
                        final count = registrations.length;
                        final max = event.maxParticipants;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count ${max != null ? 'of $max' : ''} registered',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (max != null)
                              LinearProgressIndicator(
                                value: count / max,
                                backgroundColor: Colors.grey[200],
                              ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ),
                  if (event.requiresRegistration) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => EventRegistrationDialog(
                              event: event,
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Register for Event'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildDateTimeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMMM d, y').format(event.startDate),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (event.startTime != null) ...[
          const SizedBox(height: 4),
          Text(
            '${event.startTime}${event.endTime != null ? ' - ${event.endTime}' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
        if (event.isAllDay)
          Chip(
            label: const Text('All Day'),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

