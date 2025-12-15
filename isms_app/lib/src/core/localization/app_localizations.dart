import 'package:flutter/material.dart';

/// App localization delegate
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ur', 'PK'), // Urdu
    Locale('ar', 'SA'), // Arabic
    Locale('hi', 'IN'), // Hindi
    Locale('fr', 'FR'), // French
    Locale('es', 'ES'), // Spanish
    Locale('de', 'DE'), // German
    Locale('zh', 'CN'), // Chinese (Simplified)
  ];

  // Common strings
  String get appName => _localizedValues[locale.languageCode]?['appName'] ?? 'ISMS';
  String get dashboard => _localizedValues[locale.languageCode]?['dashboard'] ?? 'Dashboard';
  String get students => _localizedValues[locale.languageCode]?['students'] ?? 'Students';
  String get staff => _localizedValues[locale.languageCode]?['staff'] ?? 'Staff';
  String get reports => _localizedValues[locale.languageCode]?['reports'] ?? 'Reports';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Edit';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Loading...';
  String get error => _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get success => _localizedValues[locale.languageCode]?['success'] ?? 'Success';
  String get noData => _localizedValues[locale.languageCode]?['noData'] ?? 'No data available';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'ISMS',
      'dashboard': 'Dashboard',
      'students': 'Students',
      'staff': 'Staff',
      'reports': 'Reports',
      'settings': 'Settings',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'noData': 'No data available',
    },
    'ur': {
      'appName': 'آئی ایس ایم ایس',
      'dashboard': 'ڈیش بورڈ',
      'students': 'طلباء',
      'staff': 'عملہ',
      'reports': 'رپورٹس',
      'settings': 'ترتیبات',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ کریں',
      'delete': 'حذف کریں',
      'edit': 'ترمیم کریں',
      'loading': 'لوڈ ہو رہا ہے...',
      'error': 'خرابی',
      'success': 'کامیابی',
      'noData': 'کوئی ڈیٹا دستیاب نہیں',
    },
    'ar': {
      'appName': 'نظام إدارة المدرسة',
      'dashboard': 'لوحة التحكم',
      'students': 'الطلاب',
      'staff': 'الموظفين',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'noData': 'لا توجد بيانات',
    },
    'hi': {
      'appName': 'आईएसएमएस',
      'dashboard': 'डैशबोर्ड',
      'students': 'छात्र',
      'staff': 'कर्मचारी',
      'reports': 'रिपोर्ट',
      'settings': 'सेटिंग्स',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'noData': 'कोई डेटा उपलब्ध नहीं',
    },
    'fr': {
      'appName': 'ISMS',
      'dashboard': 'Tableau de bord',
      'students': 'Étudiants',
      'staff': 'Personnel',
      'reports': 'Rapports',
      'settings': 'Paramètres',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'noData': 'Aucune donnée disponible',
    },
    'es': {
      'appName': 'ISMS',
      'dashboard': 'Panel de control',
      'students': 'Estudiantes',
      'staff': 'Personal',
      'reports': 'Informes',
      'settings': 'Configuración',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'noData': 'No hay datos disponibles',
    },
    'de': {
      'appName': 'ISMS',
      'dashboard': 'Dashboard',
      'students': 'Schüler',
      'staff': 'Personal',
      'reports': 'Berichte',
      'settings': 'Einstellungen',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'loading': 'Wird geladen...',
      'error': 'Fehler',
      'success': 'Erfolg',
      'noData': 'Keine Daten verfügbar',
    },
    'zh': {
      'appName': 'ISMS',
      'dashboard': '仪表板',
      'students': '学生',
      'staff': '员工',
      'reports': '报告',
      'settings': '设置',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'noData': '无可用数据',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

