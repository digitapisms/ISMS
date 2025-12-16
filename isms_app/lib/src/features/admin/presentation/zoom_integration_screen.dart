import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../data/system_settings_repository.dart';

/// Provider for system settings repository
final systemSettingsRepositoryProvider = Provider<SystemSettingsRepository>(
  (ref) => SystemSettingsRepository(),
);

/// Provider for Zoom credentials
final zoomCredentialsProvider = FutureProvider<ZoomCredentials>((ref) async {
  final repo = ref.read(systemSettingsRepositoryProvider);
  return repo.getZoomCredentials();
});

class ZoomIntegrationScreen extends ConsumerStatefulWidget {
  const ZoomIntegrationScreen({super.key});

  @override
  ConsumerState<ZoomIntegrationScreen> createState() =>
      _ZoomIntegrationScreenState();
}

class _ZoomIntegrationScreenState extends ConsumerState<ZoomIntegrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountIdController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _isLoading = false;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
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

      // Trim all credentials to remove any whitespace
      final accountId = _accountIdController.text.trim();
      final clientId = _clientIdController.text.trim();
      final clientSecret = _clientSecretController.text.trim();

      // Validate Account ID format
      if (!accountId.startsWith('C-')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account ID must start with "C-"'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final credentials = ZoomCredentials(
        accountId: accountId,
        clientId: clientId,
        clientSecret: clientSecret,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accountId = _accountIdController.text.trim();
      final clientId = _clientIdController.text.trim();
      final clientSecret = _clientSecretController.text.trim();

      if (accountId.isEmpty || clientId.isEmpty || clientSecret.isEmpty) {
        throw Exception('Please fill in all credentials before testing');
      }

      // Validate Account ID format
      if (!accountId.startsWith('C-')) {
        throw Exception('Account ID must start with "C-"');
      }

      // First, save the credentials so the Edge Function can read them
      final repo = ref.read(systemSettingsRepositoryProvider);
      final credentials = ZoomCredentials(
        accountId: accountId,
        clientId: clientId,
        clientSecret: clientSecret,
      );
      await repo.updateZoomCredentials(credentials);

      // Wait a moment for the database to update
      await Future.delayed(const Duration(milliseconds: 500));

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
              content: Text(
                '✅ Connection test successful! Zoom credentials are valid.',
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
          if (errorData['details'] != null) {
            final details = errorData['details'];
            if (details is Map && details['error'] == 'invalid_client') {
              errorMessage =
                  'Invalid Zoom credentials. Please verify:\n'
                  '• Client ID and Client Secret are correct\n'
                  '• No extra spaces in credentials\n'
                  '• OAuth app is activated in Zoom Marketplace\n'
                  '• Account ID is correct';
            }
          }
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
                                    'Get your credentials from Zoom Marketplace: marketplace.zoom.us',
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

                  // Credential Verification Info
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tip: Copy credentials directly from Zoom Marketplace → Your App → App Credentials. Ensure no extra spaces.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          'Your Zoom Account ID (starts with C-). Found in Zoom Marketplace → App Credentials',
                      suffixIcon: _accountIdController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.check_circle, size: 20),
                              color:
                                  _accountIdController.text.trim().startsWith(
                                    'C-',
                                  )
                                  ? Colors.green
                                  : Colors.orange,
                              onPressed: () {},
                              tooltip:
                                  _accountIdController.text.trim().startsWith(
                                    'C-',
                                  )
                                  ? 'Valid format'
                                  : 'Must start with C-',
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account ID is required';
                      }
                      final trimmed = value.trim();
                      if (!trimmed.startsWith('C-')) {
                        return 'Account ID must start with C-';
                      }
                      if (trimmed.length < 5) {
                        return 'Account ID seems too short';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Update suffix icon
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
                    obscureText: _obscureSecret,
                    decoration: InputDecoration(
                      labelText: 'Zoom Client Secret',
                      hintText: 'Your OAuth Client Secret',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_clientSecretController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.check_circle, size: 20),
                              color:
                                  _clientSecretController.text.trim().length >=
                                      10
                                  ? Colors.green
                                  : Colors.orange,
                              onPressed: () {},
                              tooltip:
                                  'Length: ${_clientSecretController.text.trim().length}',
                            ),
                          IconButton(
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
                        ],
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      helperText:
                          'OAuth 2.0 Client Secret (keep this secure). Usually 32 characters',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Client Secret is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Client Secret seems too short (usually 32 characters)';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {}); // Update suffix icon
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep(
                            context,
                            '1',
                            'Go to Zoom Marketplace',
                            'Visit marketplace.zoom.us and sign in with your Zoom account',
                          ),
                          _buildInstructionStep(
                            context,
                            '2',
                            'Navigate to Your App',
                            'Click "Develop" → "Build App" → Select your "Server-to-Server OAuth" app (or "Manage" → "Created Apps")',
                          ),
                          _buildInstructionStep(
                            context,
                            '3',
                            'Verify App is Activated',
                            'Go to "Activation" tab → Ensure status is "Activated" (green). If not, click "Activate" and wait.',
                          ),
                          _buildInstructionStep(
                            context,
                            '4',
                            'Get Credentials',
                            'Go to "App Credentials" tab → Copy Account ID (starts with C-), Client ID, and Client Secret. Click "Show" if Client Secret is hidden.',
                          ),
                          _buildInstructionStep(
                            context,
                            '5',
                            'Verify Scopes',
                            'Go to "Scopes" tab → Ensure these are added: meeting:write, meeting:read, user:read',
                          ),
                          _buildInstructionStep(
                            context,
                            '6',
                            'Save in ISMS',
                            'Paste credentials above (no extra spaces), click "Save Credentials", then "Test Connection"',
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
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
