import 'package:flutter/material.dart';

import '../../domain/certificate_template.dart';
import '../../domain/certificate_type.dart';
import 'template_preview_widget.dart';

class TemplateListItem extends StatelessWidget {
  final CertificateTemplate template;

  const TemplateListItem({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            template.certificateType == CertificateType.leaving
                ? Icons.school
                : template.certificateType == CertificateType.character
                    ? Icons.person
                    : Icons.workspace_premium,
          ),
        ),
        title: Text(
          template.templateName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(template.certificateType.displayName),
            if (template.description != null) ...[
              const SizedBox(height: 4),
              Text(
                template.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(
            template.isActive ? 'Active' : 'Inactive',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: template.isActive ? Colors.green[100] : Colors.grey[300],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TemplatePreviewWidget(
              template: template,
            ),
          );
        },
      ),
    );
  }
}

