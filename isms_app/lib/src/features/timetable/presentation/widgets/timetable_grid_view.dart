import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../domain/period.dart';
import '../../domain/timetable.dart';
import '../../domain/timetable_entry.dart';
import '../dialogs/timetable_entry_form_dialog.dart';

/// Grid view for displaying and editing timetable entries
class TimetableGridView extends ConsumerStatefulWidget {
  const TimetableGridView({super.key, required this.timetable});

  final Timetable timetable;

  @override
  ConsumerState<TimetableGridView> createState() => _TimetableGridViewState();
}

class _TimetableGridViewState extends ConsumerState<TimetableGridView> {
  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      timetableEntriesProvider(widget.timetable.id),
    );
    final periodsAsync = ref.watch(periodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timetable.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) =>
                    TimetableEntryFormDialog(timetable: widget.timetable),
              );
              if (result == true) {
                ref.invalidate(timetableEntriesProvider(widget.timetable.id));
              }
            },
            tooltip: 'Add Entry',
          ),
        ],
      ),
      body: periodsAsync.when(
        data: (periods) {
          final regularPeriods =
              periods
                  .where(
                    (p) => p.periodType == PeriodType.regular && p.isActive,
                  )
                  .toList()
                ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          if (regularPeriods.isEmpty) {
            return const Center(
              child: Text('No periods defined. Please add periods first.'),
            );
          }

          return entriesAsync.when(
            data: (entries) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Table(
                      border: TableBorder.all(color: Colors.grey[300]!),
                      columnWidths: {
                        0: const FixedColumnWidth(100),
                        for (int i = 1; i <= regularPeriods.length; i++)
                          i: const FixedColumnWidth(150),
                      },
                      children: [
                        // Header row
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                          ),
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Day/Period',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...regularPeriods.map((period) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Text(
                                      period.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      period.timeRange,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                        // Data rows (Monday to Friday)
                        ...List.generate(5, (dayIndex) {
                          final dayOfWeek = dayIndex + 1;
                          final dayName = _getDayName(dayOfWeek);
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  dayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...regularPeriods.map((period) {
                                final entry = entries.firstWhere(
                                  (e) =>
                                      e.dayOfWeek == dayOfWeek &&
                                      e.periodId == period.id,
                                  orElse: () => TimetableEntry(
                                    id: '',
                                    schoolId: '',
                                    timetableId: widget.timetable.id,
                                    dayOfWeek: dayOfWeek,
                                    periodId: period.id,
                                  ),
                                );

                                return InkWell(
                                  onTap: () async {
                                    final result = await showDialog(
                                      context: context,
                                      builder: (_) => TimetableEntryFormDialog(
                                        timetable: widget.timetable,
                                        entry: entry.id.isEmpty ? null : entry,
                                        dayOfWeek: dayOfWeek,
                                        periodId: period.id,
                                      ),
                                    );
                                    if (result == true) {
                                      ref.invalidate(
                                        timetableEntriesProvider(
                                          widget.timetable.id,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      color: entry.id.isEmpty
                                          ? Colors.grey[50]
                                          : Colors.blue.withOpacity(0.1),
                                    ),
                                    child: entry.id.isEmpty
                                        ? const Center(
                                            child: Icon(
                                              Icons.add,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (entry.subjectId != null)
                                                Text(
                                                  'Subject ID: ${entry.subjectId}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              if (entry.teacherId != null)
                                                Text(
                                                  'Teacher: ${entry.teacherId!.substring(0, 8)}...',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              if (entry.roomId != null)
                                                Text(
                                                  'Room: ${entry.roomId}',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading entries')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading periods')),
      ),
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
