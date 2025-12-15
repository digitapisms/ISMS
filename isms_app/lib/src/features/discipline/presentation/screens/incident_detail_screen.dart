import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/discipline_providers.dart';
import '../../domain/discipline_incident.dart';
import '../../domain/discipline_action.dart';
import '../dialogs/action_form_dialog.dart';

class IncidentDetailScreen extends ConsumerWidget {
  final DisciplineIncident incident;

  const IncidentDetailScreen({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(disciplineActionsProvider(incident.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                incident.incidentType.displayName,
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
                      Colors.red[700]!,
                      Colors.orange[700]!,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning,
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
                    icon: Icons.description,
                    title: 'Description',
                    content: Text(
                      incident.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Date & Time',
                    content: Text(
                      DateFormat('EEEE, MMMM d, y • h:mm a')
                          .format(incident.incidentDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (incident.location != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on,
                      title: 'Location',
                      content: Text(
                        incident.location!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.assignment,
                    title: 'Disciplinary Actions',
                    content: actionsAsync.when(
                      data: (actions) {
                        if (actions.isEmpty) {
                          return const Text('No actions taken yet');
                        }
                        return Column(
                          children: actions.map((action) {
                            return ListTile(
                              title: Text(action.actionType.displayName),
                              subtitle: Text(action.description),
                              trailing: Chip(
                                label: Text(action.status.displayName),
                              ),
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
                          builder: (context) => ActionFormDialog(
                            incidentId: incident.id,
                            studentId: incident.studentId,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Disciplinary Action'),
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

