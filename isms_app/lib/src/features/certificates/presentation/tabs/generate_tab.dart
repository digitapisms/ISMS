import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/certificates_providers.dart';
import '../../domain/certificate_type.dart';
import '../dialogs/generate_certificate_dialog.dart';
import '../dialogs/bulk_generate_dialog.dart';
import '../widgets/template_preview_widget.dart';

class GenerateTab extends ConsumerWidget {
  const GenerateTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(certificateTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No templates available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a template first to generate certificates',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    _getIconForType(template.certificateType),
                  ),
                ),
                title: Text(template.templateName),
                subtitle: Text(template.certificateType.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.preview),
                      tooltip: 'Preview',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => TemplatePreviewWidget(
                            template: template,
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => GenerateCertificateDialog(
                            template: template,
                          ),
                        );
                      },
                      child: const Text('Generate'),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'bulk',
                          child: Row(
                            children: [
                              Icon(Icons.batch_prediction),
                              SizedBox(width: 8),
                              Text('Bulk Generate'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'bulk') {
                          showDialog(
                            context: context,
                            builder: (context) => BulkGenerateDialog(
                              template: template,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  IconData _getIconForType(certificateType) {
    // Return appropriate icon based on certificate type
    return Icons.workspace_premium;
  }
}

