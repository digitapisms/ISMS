import 'package:flutter/material.dart';

import '../../domain/certificate_template.dart';
import '../../domain/certificate_type.dart';

class TemplatePreviewWidget extends StatelessWidget {
  final CertificateTemplate template;
  final Map<String, String> sampleData;

  const TemplatePreviewWidget({
    super.key,
    required this.template,
    this.sampleData = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Replace template variables with sample data
    String content = template.templateContent;
    for (var variable in template.templateVariables) {
      final value = sampleData[variable] ?? _getDefaultValue(variable);
      content = content.replaceAll('{$variable}', value);
    }

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Template Preview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        template.certificateType.displayName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (template.signature1Label != null)
                            Column(
                              children: [
                                Container(
                                  width: 150,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Signature',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  template.signature1Label!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          if (template.sealImageUrl != null)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(Icons.verified, size: 40),
                            ),
                          if (template.signature2Label != null)
                            Column(
                              children: [
                                Container(
                                  width: 150,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Signature',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  template.signature2Label!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Generate and preview PDF
                    Navigator.pop(context);
                  },
                  child: const Text('Generate PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultValue(String variable) {
    final defaults = {
      'student_name': 'John Doe',
      'staff_name': 'Jane Smith',
      'date': DateTime.now().toString().split(' ')[0],
      'class': '10th',
      'section': 'A',
      'school_name': 'School Name',
      'year': DateTime.now().year.toString(),
      'grade': 'A+',
      'percentage': '95%',
    };
    return defaults[variable.toLowerCase()] ?? 'Sample Value';
  }
}

