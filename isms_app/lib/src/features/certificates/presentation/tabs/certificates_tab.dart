import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/certificates_providers.dart';
import '../widgets/certificate_list_item.dart';

class CertificatesTab extends ConsumerWidget {
  const CertificatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificatesAsync = ref.watch(certificatesProvider);

    return certificatesAsync.when(
      data: (certificates) {
        if (certificates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No certificates generated yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: certificates.length,
          itemBuilder: (context, index) {
            return CertificateListItem(
              certificate: certificates[index],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading certificates: $error',
          style: TextStyle(color: Colors.red[600]),
        ),
      ),
    );
  }
}

