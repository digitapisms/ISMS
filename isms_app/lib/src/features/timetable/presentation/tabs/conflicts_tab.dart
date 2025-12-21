import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timetable_providers.dart';
import '../../../../core/tenant/school_context_provider.dart';
import '../../../../core/tenant/tenant_context.dart';
import '../../../authentication/application/auth_providers.dart';

/// Tab for detecting and resolving schedule conflicts
class ConflictsTab extends ConsumerStatefulWidget {
  const ConflictsTab({super.key});

  @override
  ConsumerState<ConflictsTab> createState() => _ConflictsTabState();
}

class _ConflictsTabState extends ConsumerState<ConflictsTab> {
  List<Map<String, dynamic>>? _conflicts;
  bool _isLoading = false;

  Future<void> _detectConflicts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tenantSchool = ref.read(tenantContextProvider);
      final authUser = ref.read(authStateProvider);
      final loadedSchool =
          tenantSchool ?? await ref.read(schoolContextLoaderProvider.future);
      final schoolId = loadedSchool?.id ?? authUser?.schoolId;
      if (schoolId == null) {
        throw Exception('School context not available. Please sign in again.');
      }

      final repo = ref.read(timetableRepositoryProvider);
      final conflicts = await repo.detectConflicts(schoolId: schoolId);

      setState(() {
        _conflicts = conflicts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectConflicts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedule Conflicts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _detectConflicts,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Detect Conflicts'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conflicts == null
                ? const Center(child: Text('Click "Detect Conflicts" to scan'))
                : _conflicts!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conflicts found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All schedules are conflict-free',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _conflicts!.length,
                    itemBuilder: (context, index) {
                      final conflict = _conflicts![index];
                      final conflictType = conflict['conflict_type'] as String;
                      final details =
                          conflict['details'] as Map<String, dynamic>?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.red.withOpacity(0.1),
                        child: ListTile(
                          leading: const Icon(Icons.warning, color: Colors.red),
                          title: Text(
                            conflictType == 'teacher_conflict'
                                ? 'Teacher Conflict'
                                : 'Room Conflict',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: details != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (details['teacher_id'] != null)
                                      Text(
                                        'Teacher ID: ${details['teacher_id']}',
                                      ),
                                    if (details['room_id'] != null)
                                      Text('Room ID: ${details['room_id']}'),
                                    Text(
                                      'Day: ${_getDayName(details['day_of_week'] as int? ?? 0)}',
                                    ),
                                    if (details['class1'] != null &&
                                        details['class2'] != null)
                                      Text(
                                        'Classes: ${details['class1']} & ${details['class2']}',
                                      ),
                                  ],
                                )
                              : null,
                          trailing: const Icon(Icons.arrow_forward_ios),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
