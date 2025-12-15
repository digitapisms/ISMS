import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/discipline_providers.dart';
import '../../domain/discipline_incident.dart';

class ReportsTab extends ConsumerWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(disciplineIncidentsProvider);

    return incidentsAsync.when(
      data: (incidents) {
        // Calculate statistics
        final totalIncidents = incidents.length;
        final byType = <IncidentType, int>{};
        final byStatus = <IncidentStatus, int>{};
        final bySeverity = <SeverityLevel, int>{};

        for (final incident in incidents) {
          byType[incident.incidentType] =
              (byType[incident.incidentType] ?? 0) + 1;
          byStatus[incident.status] = (byStatus[incident.status] ?? 0) + 1;
          bySeverity[incident.severityLevel] =
              (bySeverity[incident.severityLevel] ?? 0) + 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard(
                context,
                'Total Incidents',
                totalIncidents.toString(),
                Icons.report_problem,
                Colors.red,
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'By Type',
                byType.entries.map((e) => _StatItem(
                      label: e.key.displayName,
                      value: e.value.toString(),
                    )),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'By Status',
                byStatus.entries.map((e) => _StatItem(
                      label: e.key.displayName,
                      value: e.value.toString(),
                    )),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'By Severity',
                bySeverity.entries.map((e) => _StatItem(
                      label: e.key.displayName,
                      value: e.value.toString(),
                    )),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    Iterable<_StatItem> items,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem({required this.label, required this.value});
}

