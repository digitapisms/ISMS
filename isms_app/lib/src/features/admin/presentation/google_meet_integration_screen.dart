import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../data/system_settings_repository.dart';

/// Provider for Google Meet credentials
final googleMeetCredentialsProvider = FutureProvider<GoogleMeetCredentials>((
  ref,
) async {
  final repo = ref.read(systemSettingsRepositoryProvider);
  return repo.getGoogleMeetCredentials();
});

class GoogleMeetIntegrationScreen extends ConsumerStatefulWidget {
  const GoogleMeetIntegrationScreen({super.key});

  @override
  ConsumerState<GoogleMeetIntegrationScreen> createState() =>
      _GoogleMeetIntegrationScreenState();
}

class _GoogleMeetIntegrationScreenState
    extends ConsumerState<GoogleMeetIntegrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientEmailController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _projectIdController = TextEditingController();
  bool _isLoading = false;
  bool _obscureKey = true;

  @override
  void dispose() {
    _clientEmailController.dispose();
    _privateKeyController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(systemSettingsRepositoryProvider);

      final credentials = GoogleMeetCredentials(
        clientEmail: _clientEmailController.text.trim(),
        privateKey: _privateKeyController.text.trim(),
        projectId: _projectIdController.text.trim(),
      );

      await repo.updateGoogleMeetCredentials(credentials);

      // Refresh the provider
      ref.invalidate(googleMeetCredentialsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Meet credentials saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clientEmail = _clientEmailController.text.trim();
      final privateKey = _privateKeyController.text.trim();
      final projectId = _projectIdController.text.trim();

      if (clientEmail.isEmpty || privateKey.isEmpty || projectId.isEmpty) {
        throw Exception('Please fill in all credentials before testing');
      }

      // First, save the credentials so the Edge Function can read them
      final repo = ref.read(systemSettingsRepositoryProvider);
      final credentials = GoogleMeetCredentials(
        clientEmail: clientEmail,
        privateKey: privateKey,
        projectId: projectId,
      );
      await repo.updateGoogleMeetCredentials(credentials);

      // Wait a moment for the database to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Test by trying to create a test meeting
      final response = await SupabaseManager.client.functions.invoke(
        'create-google-meet',
        body: {
          'title': 'ISMS Connection Test',
          'startTime': DateTime.now()
              .add(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
          'duration': 15,
        },
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Connection test successful! Google Meet credentials are valid.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        final errorData = response.data;
        String errorMessage = 'Test failed';
        if (errorData is Map) {
          errorMessage = errorData['error']?.toString() ?? errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection test failed: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credentialsAsync = ref.watch(googleMeetCredentialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Meet Integration Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: credentialsAsync.when(
        data: (credentials) {
          // Update controllers if data loaded
          if (_clientEmailController.text != credentials.clientEmail) {
            _clientEmailController.text = credentials.clientEmail;
            _privateKeyController.text = credentials.privateKey;
            _projectIdController.text = credentials.projectId;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.video_call,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Google Meet API Integration',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Configure Google Cloud Service Account credentials to enable Google Meet meetings. '
                            'These credentials are used to create Google Meet conferences automatically when '
                            'online classes are scheduled.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Get your credentials from Google Cloud Console: console.cloud.google.com',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Client Email Field
                  TextFormField(
                    controller: _clientEmailController,
                    decoration: InputDecoration(
                      labelText: 'Service Account Email',
                      hintText:
                          'your-service-account@project-id.iam.gserviceaccount.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText:
                          'Service Account Email from Google Cloud Console',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Service Account Email is required';
                      }
                      if (!value.contains('@') ||
                          !value.contains('.iam.gserviceaccount.com')) {
                        return 'Invalid Service Account Email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Private Key Field
                  TextFormField(
                    controller: _privateKeyController,
                    obscureText: _obscureKey,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Private Key (JSON)',
                      hintText: 'Paste the entire private key JSON here',
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureKey = !_obscureKey;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText:
                          'Private Key JSON from Google Cloud Service Account',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Private Key is required';
                      }
                      try {
                        // Basic JSON validation
                        if (!value.trim().startsWith('{')) {
                          return 'Private Key must be valid JSON';
                        }
                      } catch (e) {
                        return 'Invalid JSON format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Project ID Field
                  TextFormField(
                    controller: _projectIdController,
                    decoration: InputDecoration(
                      labelText: 'Google Cloud Project ID',
                      hintText: 'your-project-id',
                      prefixIcon: const Icon(Icons.folder),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Google Cloud Project ID',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Project ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: const Icon(Icons.wifi_protected_setup),
                          label: const Text('Test Connection'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveCredentials,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isLoading ? 'Saving...' : 'Save Credentials',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Instructions Card
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How to Get Google Meet Credentials',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(
                            context,
                            '1',
                            'Go to Google Cloud Console',
                            'Visit console.cloud.google.com and select or create a project',
                          ),
                          _buildInstructionStep(
                            context,
                            '2',
                            'Enable Google Meet API',
                            'Navigate to APIs & Services → Library → Search "Google Meet API" → Enable',
                          ),
                          _buildInstructionStep(
                            context,
                            '3',
                            'Create Service Account',
                            'Go to IAM & Admin → Service Accounts → Create Service Account',
                          ),
                          _buildInstructionStep(
                            context,
                            '4',
                            'Generate Private Key',
                            'Click on Service Account → Keys → Add Key → Create new key → JSON → Create',
                          ),
                          _buildInstructionStep(
                            context,
                            '5',
                            'Copy Credentials',
                            'Copy the client_email, private_key, and project_id from the downloaded JSON file',
                          ),
                          _buildInstructionStep(
                            context,
                            '6',
                            'Save in ISMS',
                            'Paste credentials above, click "Save Credentials", then "Test Connection"',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading credentials: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(googleMeetCredentialsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
