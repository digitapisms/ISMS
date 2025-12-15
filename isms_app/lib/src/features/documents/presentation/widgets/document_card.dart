import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/document.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
  });

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('image')) {
      return Icons.image;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String mimeType) {
    if (mimeType.contains('pdf')) {
      return Colors.red;
    } else if (mimeType.contains('image')) {
      return Colors.green;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Colors.blue;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Colors.green[700]!;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () async {
          final url = Uri.parse(document.fileUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getFileColor(document.mimeType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileIcon(document.mimeType),
                  color: _getFileColor(document.mimeType),
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                document.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                document.fileSizeFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (document.documentType != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    document.documentType!.replaceAll('_', ' ').toUpperCase(),
                  ),
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

