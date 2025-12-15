import 'package:flutter/material.dart';

import '../../domain/digital_resource.dart';
import '../../domain/book_type.dart';

class DigitalResourceItem extends StatelessWidget {
  const DigitalResourceItem({super.key, required this.resource});

  final DigitalResource resource;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Open resource viewer
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: resource.thumbnailUrl != null
                    ? Image.network(
                        resource.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _buildIcon(),
                      )
                    : _buildIcon(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(resource.resourceType.displayName),
                        backgroundColor: _getTypeColor(resource.resourceType)
                            .withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getTypeColor(resource.resourceType),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.fileSizeFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (resource.resourceType) {
      case DigitalResourceType.ebook:
      case DigitalResourceType.pdf:
        icon = Icons.picture_as_pdf;
        break;
      case DigitalResourceType.audio:
        icon = Icons.audiotrack;
        break;
      case DigitalResourceType.video:
        icon = Icons.video_library;
        break;
      case DigitalResourceType.document:
        icon = Icons.description;
        break;
    }

    return Center(
      child: Icon(icon, size: 48, color: Colors.grey[400]),
    );
  }

  Color _getTypeColor(DigitalResourceType type) {
    switch (type) {
      case DigitalResourceType.ebook:
        return Colors.blue;
      case DigitalResourceType.pdf:
        return Colors.red;
      case DigitalResourceType.audio:
        return Colors.purple;
      case DigitalResourceType.video:
        return Colors.orange;
      case DigitalResourceType.document:
        return Colors.green;
    }
  }
}

