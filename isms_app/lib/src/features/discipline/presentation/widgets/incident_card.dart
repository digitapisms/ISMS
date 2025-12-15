import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/discipline_incident.dart';

class IncidentCard extends StatelessWidget {
  final DisciplineIncident incident;
  final VoidCallback? onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
  });

  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low:
        return Colors.green;
      case SeverityLevel.medium:
        return Colors.orange;
      case SeverityLevel.high:
        return Colors.red;
      case SeverityLevel.critical:
        return Colors.purple;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.reported:
        return Colors.blue;
      case IncidentStatus.investigating:
        return Colors.orange;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.closed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getSeverityColor(incident.severityLevel).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(incident.severityLevel)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: _getSeverityColor(incident.severityLevel),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.incidentType.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, y').format(incident.incidentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(incident.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      incident.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(incident.status),
                      ),
                    ),
                  ),
                ],
              ),
              if (incident.category != null) ...[
                const SizedBox(height: 12),
                Chip(
                  label: Text(incident.category!),
                  padding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                incident.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (incident.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      incident.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

