import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notification_providers.dart';
import '../domain/notification.dart';
import '../services/notification_service.dart';

class SendNotificationDialog extends ConsumerStatefulWidget {
  const SendNotificationDialog({super.key});

  @override
  ConsumerState<SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState
    extends ConsumerState<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  NotificationType _selectedType = NotificationType.email;
  String? _selectedTemplateKey;
  bool _useTemplate = false;
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    try {
      final service = ref.read(notificationServiceProvider);

      NotificationResult result;

      if (_useTemplate && _selectedTemplateKey != null) {
        // Get variables from body (simple approach - in production, use a proper form)
        final variables = <String, String>{};
        // For now, we'll use a simple approach
        // In production, you'd have a proper variable input form

        result = await service.sendTemplatedNotification(
          templateKey: _selectedTemplateKey!,
          recipientEmail: _emailController.text.trim(),
          recipientPhone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          variables: variables,
        );
      } else {
        result = await service.sendNotification(
          type: _selectedType,
          recipient: _selectedType == NotificationType.email
              ? _emailController.text.trim()
              : _phoneController.text.trim(),
          body: _bodyController.text.trim(),
          subject: _selectedType == NotificationType.email
              ? _subjectController.text.trim()
              : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Notification sent successfully'
                  : 'Notification failed: ${result.error ?? "Unknown error"}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(notificationTemplatesProvider(null));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Send Notification'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<NotificationType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Notification Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: NotificationType.email,
                            child: Text('Email'),
                          ),
                          DropdownMenuItem(
                            value: NotificationType.sms,
                            child: Text('SMS'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Use Template'),
                        subtitle: const Text('Select a pre-defined template'),
                        value: _useTemplate,
                        onChanged: (value) {
                          setState(() {
                            _useTemplate = value;
                          });
                        },
                      ),
                      if (_useTemplate) ...[
                        const SizedBox(height: 16),
                        templatesAsync.when(
                          data: (templates) => DropdownButtonFormField<String>(
                            initialValue: _selectedTemplateKey,
                            decoration: const InputDecoration(
                              labelText: 'Template *',
                              border: OutlineInputBorder(),
                            ),
                            items: templates.map((template) {
                              return DropdownMenuItem(
                                value: template.templateKey,
                                child: Text(template.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTemplateKey = value;
                              });
                            },
                            validator: (value) {
                              if (_useTemplate &&
                                  (value == null || value.isEmpty)) {
                                return 'Please select a template';
                              }
                              return null;
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) =>
                              const Text('Error loading templates'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_selectedType == NotificationType.email) ...[
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (_selectedType == NotificationType.email &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Email is required';
                            }
                            if (value != null && !value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_selectedType == NotificationType.email &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Subject is required';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: '+1234567890',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (_selectedType == NotificationType.sms &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (!_useTemplate &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Message is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSending
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSending ? null : _send,
                      child: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
