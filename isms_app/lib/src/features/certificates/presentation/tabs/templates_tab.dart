import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/certificates_providers.dart';
import '../widgets/template_list_item.dart';
import '../dialogs/template_form_dialog.dart';

class TemplatesTab extends ConsumerWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(certificateTemplatesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const TemplateFormDialog(),
          );
          ref.invalidate(certificateTemplatesProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
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
                    'No certificate templates yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a template to start generating certificates',
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
            padding: const EdgeInsets.all(8),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return TemplateListItem(
                template: templates[index],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading templates: $error',
            style: TextStyle(color: Colors.red[600]),
          ),
        ),
      ),
    );
  }
}

