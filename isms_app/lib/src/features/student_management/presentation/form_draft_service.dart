import 'package:hive_flutter/hive_flutter.dart';

/// Service to auto-save form drafts locally
class FormDraftService {
  static const String _boxName = 'form_drafts';
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save draft for student registration form
  static Future<void> saveRegistrationDraft(Map<String, dynamic> data) async {
    if (_box == null) await init();
    await _box!.put('student_registration', data);
  }

  /// Load draft for student registration form
  static Map<String, dynamic>? loadRegistrationDraft() {
    if (_box == null) return null;
    return _box!.get('student_registration') as Map<String, dynamic>?;
  }

  /// Clear draft
  static Future<void> clearRegistrationDraft() async {
    if (_box == null) await init();
    await _box!.delete('student_registration');
  }

  /// Save draft for edit application form
  static Future<void> saveEditApplicationDraft(
    String applicationId,
    Map<String, dynamic> data,
  ) async {
    if (_box == null) await init();
    await _box!.put('edit_application_$applicationId', data);
  }

  /// Load draft for edit application form
  static Map<String, dynamic>? loadEditApplicationDraft(String applicationId) {
    if (_box == null) return null;
    return _box!.get('edit_application_$applicationId')
        as Map<String, dynamic>?;
  }

  /// Clear edit application draft
  static Future<void> clearEditApplicationDraft(String applicationId) async {
    if (_box == null) await init();
    await _box!.delete('edit_application_$applicationId');
  }
}
