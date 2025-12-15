import 'package:flutter/material.dart';

import '../../domain/message_template.dart';
import '../../domain/messaging_type.dart';

class TemplateListItem extends StatelessWidget {
  final MessageTemplate template;

  const TemplateListItem({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(
          template.templateName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              template.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (template.templateCategory != null) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(template.templateCategory!.displayName),
                labelStyle: const TextStyle(fontSize: 10),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            if (template.usageCount > 0)
              Text(
                '${template.usageCount} uses',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(template.templateName),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (template.subject != null) ...[
                      Text(
                        'Subject: ${template.subject}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(template.content),
                    if (template.variables != null && template.variables!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Variables:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...template.variables!.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text('• $v'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

