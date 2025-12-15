import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/certificate.dart';
import '../../domain/certificate_type.dart';

class CertificateListItem extends ConsumerWidget {
  final Certificate certificate;

  const CertificateListItem({
    super.key,
    required this.certificate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: Icon(
            Icons.workspace_premium,
            color: Colors.amber[800],
          ),
        ),
        title: Text(
          certificate.recipientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(certificate.certificateType.displayName),
            const SizedBox(height: 4),
            Text(
              'Certificate #: ${certificate.certificateNumber}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Issued: ${DateFormat('MMM d, y').format(certificate.issuedDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (certificate.pdfUrl != null)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // TODO: Download PDF
                },
                tooltip: 'Download PDF',
              ),
            PopupMenuButton(
              itemBuilder: (context) => [
                if (certificate.pdfUrl == null)
                  const PopupMenuItem(
                    value: 'generate_pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf),
                        SizedBox(width: 8),
                        Text('Generate PDF'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'send_email',
                  child: Row(
                    children: [
                      Icon(Icons.email),
                      SizedBox(width: 8),
                      Text('Send via Email'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                // TODO: Handle PDF generation and email sending
              },
            ),
            if (certificate.isDownloaded)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
          ],
        ),
        onTap: () {
          // TODO: Show certificate preview
        },
      ),
    );
  }
}

