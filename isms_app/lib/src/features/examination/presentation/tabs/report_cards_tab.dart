import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/examination_providers.dart';
import '../../domain/report_card.dart';
import '../dialogs/report_card_generation_dialog.dart';
import '../widgets/report_card_pdf_service.dart';

/// Tab for managing report cards
class ReportCardsTab extends ConsumerWidget {
  const ReportCardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportCardsAsync = ref.watch(reportCardsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report Cards',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const ReportCardGenerationDialog(),
                  );
                  if (result == true) {
                    ref.invalidate(reportCardsProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Generate Report Card'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: reportCardsAsync.when(
              data: (reportCards) {
                if (reportCards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No report cards yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate report cards for students',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reportCards.length,
                  itemBuilder: (context, index) {
                    final reportCard = reportCards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.description,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${reportCard.academicYear} - ${reportCard.term}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student ID: ${reportCard.studentId.substring(0, 8)}...',
                            ),
                            if (reportCard.overallPercentage != null)
                              Text(
                                'Percentage: ${reportCard.overallPercentage!.toStringAsFixed(2)}%',
                              ),
                            if (reportCard.overallGrade != null)
                              Text('Grade: ${reportCard.overallGrade}'),
                            if (reportCard.division != null)
                              Text('Division: ${reportCard.division}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print),
                              onPressed: () async {
                                // TODO: Generate and print PDF
                                await ReportCardPdfService.generateAndPrint(
                                  reportCard: reportCard,
                                );
                              },
                              tooltip: 'Print Report Card',
                            ),
                            Chip(
                              label: Text(reportCard.status.displayName),
                              backgroundColor: _getStatusColor(
                                reportCard.status,
                              ).withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: _getStatusColor(reportCard.status),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Show report card details
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading report cards',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportCardStatus status) {
    switch (status) {
      case ReportCardStatus.draft:
        return Colors.orange;
      case ReportCardStatus.published:
        return Colors.green;
      case ReportCardStatus.archived:
        return Colors.grey;
    }
  }
}
