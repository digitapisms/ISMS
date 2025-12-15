import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../data/system_settings_repository.dart';

/// Provider for system settings repository
final systemSettingsRepositoryProvider =
    Provider<SystemSettingsRepository>((ref) => SystemSettingsRepository());

/// Provider for Zoom credentials
final zoomCredentialsProvider =
    FutureProvider<ZoomCredentials>((ref) async {
  final repo = ref.read(systemSettingsRepositoryProvider);
  return repo.getZoomCredentials();
});

class ZoomIntegrationScreen extends ConsumerStatefulWidget {
  const ZoomIntegrationScreen({super.key});

  @override
  ConsumerState<ZoomIntegrationScreen> createState() =>
      _ZoomIntegrationScreenState();
}

class _ZoomIntegrationScreenState
    extends ConsumerState<ZoomIntegrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountIdController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _isLoading = false;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final credentialsAsync = ref.read(zoomCredentialsProvider);
    credentialsAsync.whenData((credentials) {
      _accountIdController.text = credentials.accountId;
      _clientIdController.text = credentials.clientId;
      _clientSecretController.text = credentials.clientSecret;
    });
  }

  @override
  void dispose() {
    _accountIdController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
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
      final credentials = ZoomCredentials(
        accountId: _accountIdController.text.trim(),
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim(),
      );

      await repo.updateZoomCredentials(credentials);

      // Refresh the provider
      ref.invalidate(zoomCredentialsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zoom credentials saved successfully!'),
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
    setState(() {
      _isLoading = true;
    });

    try {
      final credentials = ZoomCredentials(
        accountId: _accountIdController.text.trim(),
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim(),
      );

      if (!credentials.isValid) {
        throw Exception('Please fill in all credentials before testing');
      }

      // Test by trying to create a test meeting
      final response = await SupabaseManager.client.functions.invoke(
        'create-zoom-meeting',
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
              content: Text('✅ Connection test successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Test failed: ${response.data}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection test failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    final credentialsAsync = ref.watch(zoomCredentialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoom Integration Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: credentialsAsync.when(
        data: (credentials) {
          // Update controllers if data loaded
          if (_accountIdController.text != credentials.accountId) {
            _accountIdController.text = credentials.accountId;
            _clientIdController.text = credentials.clientId;
            _clientSecretController.text = credentials.clientSecret;
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
                                  'Zoom API Integration',
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
                            'Configure Zoom API credentials to enable online class meetings. '
                            'These credentials are used to create Zoom meetings automatically when '
                            'online classes are scheduled.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3),
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
                                    'Get your credentials from Zoom Marketplace: marketplace.zoom.us',
                                    style: Theme.of(context).textTheme.bodySmall,
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

                  // Account ID Field
                  TextFormField(
                    controller: _accountIdController,
                    decoration: InputDecoration(
                      labelText: 'Zoom Account ID',
                      hintText: 'C-xxxxxxxxxxxxx',
                      prefixIcon: const Icon(Icons.account_circle),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText:
                          'Your Zoom Account ID (starts with C-)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account ID is required';
                      }
                      if (!value.trim().startsWith('C-')) {
                        return 'Account ID should start with C-';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Client ID Field
                  TextFormField(
                    controller: _clientIdController,
                    decoration: InputDecoration(
                      labelText: 'Zoom Client ID',
                      hintText: 'Your OAuth Client ID',
                      prefixIcon: const Icon(Icons.vpn_key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'OAuth 2.0 Client ID from Zoom Marketplace',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Client ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Client Secret Field
                  TextFormField(
                    controller: _clientSecretController,
                    decoration: InputDecoration(
                      labelText: 'Zoom Client Secret',
                      hintText: 'Your OAuth Client Secret',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecret
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureSecret = !_obscureSecret;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText:
                          'OAuth 2.0 Client Secret (keep this secure)',
                    ),
                    obscureText: _obscureSecret,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Client Secret is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Client Secret seems too short';
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
                          label: Text(_isLoading ? 'Saving...' : 'Save Credentials'),
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
                    color: Theme.of(context).colorScheme.surfaceVariant,
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
                                'How to Get Zoom Credentials',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(
                            context,
                            '1',
                            'Go to Zoom Marketplace',
                            'Visit marketplace.zoom.us and sign in',
                          ),
                          _buildInstructionStep(
                            context,
                            '2',
                            'Create OAuth App',
                            'Click "Develop" → "Build App" → Select "OAuth" → "Server-to-Server OAuth"',
                          ),
                          _buildInstructionStep(
                            context,
                            '3',
                            'Copy Credentials',
                            'Copy Account ID, Client ID, and Client Secret',
                          ),
                          _buildInstructionStep(
                            context,
                            '4',
                            'Save Here',
                            'Paste credentials above and click "Save Credentials"',
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
                  ref.invalidate(zoomCredentialsProvider);
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
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

