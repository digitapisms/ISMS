import 'package:flutter/material.dart';

import '../../domain/timetable_entry.dart';

/// View for displaying teacher timetable
class TeacherTimetableView extends StatelessWidget {
  const TeacherTimetableView({super.key, required this.entries});

  final List<TimetableEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Group entries by day
    final entriesByDay = <int, List<TimetableEntry>>{};
    for (final entry in entries) {
      entriesByDay.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Monday to Friday
      itemBuilder: (context, index) {
        final dayOfWeek = index + 1;
        final dayEntries = entriesByDay[dayOfWeek] ?? [];
        final dayName = _getDayName(dayOfWeek);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(dayName, style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('${dayEntries.length} periods'),
            children: dayEntries.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No classes scheduled'),
                    ),
                  ]
                : dayEntries.map((entry) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          'P${entry.periodId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text('Period ${entry.periodId}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.subjectId != null)
                            Text('Subject ID: ${entry.subjectId}'),
                          if (entry.roomId != null)
                            Text('Room ID: ${entry.roomId}'),
                          if (entry.notes != null)
                            Text('Notes: ${entry.notes}'),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        );
      },
    );
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}
