import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

/// Repository for managing system-wide settings
class SystemSettingsRepository {
  final SupabaseClient _client = SupabaseManager.client;

  /// Get a system setting value by key
  Future<String?> getSetting(String key) async {
    try {
      final response = await _client
          .from('system_settings')
          .select('setting_value')
          .eq('setting_key', key)
          .maybeSingle();

      return response?['setting_value'] as String?;
    } catch (e) {
      throw Exception('Failed to get system setting: $e');
    }
  }

  /// Get all system settings
  Future<Map<String, String>> getAllSettings() async {
    try {
      final response = await _client
          .from('system_settings')
          .select('setting_key, setting_value');

      final settings = <String, String>{};
      for (final row in response) {
        settings[row['setting_key'] as String] = row['setting_value'] as String;
      }
      return settings;
    } catch (e) {
      throw Exception('Failed to get system settings: $e');
    }
  }

  /// Update or create a system setting
  Future<void> setSetting({
    required String key,
    required String value,
    String? description,
    bool isEncrypted = false,
  }) async {
    try {
      final userId = await _getCurrentUserId();

      // Check if setting exists first
      final existing = await _client
          .from('system_settings')
          .select('id')
          .eq('setting_key', key)
          .maybeSingle();

      if (existing != null) {
        // Update existing setting
        await _client.from('system_settings').update({
          'setting_value': value,
          'description': description,
          'is_encrypted': isEncrypted,
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('setting_key', key);
      } else {
        // Insert new setting
        await _client.from('system_settings').insert({
          'setting_key': key,
          'setting_value': value,
          'description': description,
          'is_encrypted': isEncrypted,
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to set system setting: $e');
    }
  }

  /// Delete a system setting
  Future<void> deleteSetting(String key) async {
    try {
      await _client.from('system_settings').delete().eq('setting_key', key);
    } catch (e) {
      throw Exception('Failed to delete system setting: $e');
    }
  }

  /// Get Zoom credentials
  Future<ZoomCredentials> getZoomCredentials() async {
    try {
      final accountId = await getSetting('ZOOM_ACCOUNT_ID');
      final clientId = await getSetting('ZOOM_CLIENT_ID');
      final clientSecret = await getSetting('ZOOM_CLIENT_SECRET');

      return ZoomCredentials(
        accountId: accountId ?? '',
        clientId: clientId ?? '',
        clientSecret: clientSecret ?? '',
      );
    } catch (e) {
      // If settings don't exist or query fails, return empty credentials
      // This allows the UI to show empty fields for initial setup
      return ZoomCredentials(accountId: '', clientId: '', clientSecret: '');
    }
  }

  /// Update Zoom credentials
  Future<void> updateZoomCredentials(ZoomCredentials credentials) async {
    try {
      // Update database
      await setSetting(
        key: 'ZOOM_ACCOUNT_ID',
        value: credentials.accountId,
        description: 'Zoom Account ID for OAuth authentication',
        isEncrypted: true,
      );
      await setSetting(
        key: 'ZOOM_CLIENT_ID',
        value: credentials.clientId,
        description: 'Zoom OAuth Client ID',
        isEncrypted: true,
      );
      await setSetting(
        key: 'ZOOM_CLIENT_SECRET',
        value: credentials.clientSecret,
        description: 'Zoom OAuth Client Secret',
        isEncrypted: true,
      );

      // Update Supabase Edge Function secrets via Edge Function
      await _updateSupabaseSecrets(credentials);
    } catch (e) {
      throw Exception('Failed to update Zoom credentials: $e');
    }
  }

  /// Update Supabase Edge Function secrets
  Future<void> _updateSupabaseSecrets(ZoomCredentials credentials) async {
    try {
      await _client.functions.invoke(
        'update-zoom-secrets',
        body: {
          'ZOOM_ACCOUNT_ID': credentials.accountId,
          'ZOOM_CLIENT_ID': credentials.clientId,
          'ZOOM_CLIENT_SECRET': credentials.clientSecret,
        },
      );
    } catch (e) {
      // If Edge Function doesn't exist, log warning but don't fail
      // The credentials are still saved in the database
      print('Warning: Could not update Supabase secrets: $e');
      print('Please update secrets manually in Supabase Dashboard');
    }
  }

  /// Get Google Meet credentials
  Future<GoogleMeetCredentials> getGoogleMeetCredentials() async {
    try {
      final clientEmail = await getSetting('GOOGLE_MEET_CLIENT_EMAIL');
      final privateKey = await getSetting('GOOGLE_MEET_PRIVATE_KEY');
      final projectId = await getSetting('GOOGLE_MEET_PROJECT_ID');

      return GoogleMeetCredentials(
        clientEmail: clientEmail ?? '',
        privateKey: privateKey ?? '',
        projectId: projectId ?? '',
      );
    } catch (e) {
      // If settings don't exist or query fails, return empty credentials
      return GoogleMeetCredentials(
        clientEmail: '',
        privateKey: '',
        projectId: '',
      );
    }
  }

  /// Update Google Meet credentials
  Future<void> updateGoogleMeetCredentials(
    GoogleMeetCredentials credentials,
  ) async {
    try {
      // Update database
      await setSetting(
        key: 'GOOGLE_MEET_CLIENT_EMAIL',
        value: credentials.clientEmail,
        description: 'Google Service Account Email for Google Meet API',
        isEncrypted: true,
      );
      await setSetting(
        key: 'GOOGLE_MEET_PRIVATE_KEY',
        value: credentials.privateKey,
        description: 'Google Service Account Private Key (JSON)',
        isEncrypted: true,
      );
      await setSetting(
        key: 'GOOGLE_MEET_PROJECT_ID',
        value: credentials.projectId,
        description: 'Google Cloud Project ID',
        isEncrypted: false,
      );
    } catch (e) {
      throw Exception('Failed to update Google Meet credentials: $e');
    }
  }

  Future<String?> _getCurrentUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    return response?['id'] as String?;
  }
}

/// Zoom credentials model
class ZoomCredentials {
  final String accountId;
  final String clientId;
  final String clientSecret;

  ZoomCredentials({
    required this.accountId,
    required this.clientId,
    required this.clientSecret,
  });

  bool get isValid =>
      accountId.isNotEmpty && clientId.isNotEmpty && clientSecret.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'clientId': clientId,
      'clientSecret': clientSecret,
    };
  }

  factory ZoomCredentials.fromMap(Map<String, dynamic> map) {
    return ZoomCredentials(
      accountId: map['accountId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientSecret: map['clientSecret'] as String? ?? '',
    );
  }
}

/// Google Meet credentials model
class GoogleMeetCredentials {
  final String clientEmail;
  final String privateKey;
  final String projectId;

  GoogleMeetCredentials({
    required this.clientEmail,
    required this.privateKey,
    required this.projectId,
  });

  bool get isValid =>
      clientEmail.isNotEmpty && privateKey.isNotEmpty && projectId.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'clientEmail': clientEmail,
      'privateKey': privateKey,
      'projectId': projectId,
    };
  }

  factory GoogleMeetCredentials.fromMap(Map<String, dynamic> map) {
    return GoogleMeetCredentials(
      clientEmail: map['clientEmail'] as String? ?? '',
      privateKey: map['privateKey'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
    );
  }
}
