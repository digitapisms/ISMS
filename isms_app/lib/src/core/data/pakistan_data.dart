/// Pakistan-specific data constants

class PakistanData {
  static const List<String> provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa (KPK)',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Jammu and Kashmir (AJK)',
    'Islamabad Capital Territory',
  ];

  static const List<String> registrationTypes = [
    'Private',
    'Public',
    'Semi-Private',
    'Madrassa',
    'International',
    'Cambridge',
    'O-Levels',
  ];

  static const List<String> registrationBoards = [
    'FBISE (Federal Board)',
    'Punjab Board',
    'Sindh Board',
    'KPK Board',
    'Balochistan Board',
    'Cambridge International',
    'Edexcel',
    'IB (International Baccalaureate)',
    'AQA',
    'Other',
  ];

  static const List<String> mediumOfInstruction = [
    'English',
    'Urdu',
    'Bilingual (English/Urdu)',
    'Arabic',
    'Other',
  ];

  static const List<String> educationLevels = [
    'Pre-School',
    'Primary (Class 1-5)',
    'Middle (Class 6-8)',
    'Secondary (Class 9-10)',
    'Higher Secondary (Class 11-12)',
    'A-Levels',
    'O-Levels',
  ];

  static const List<String> genderTypes = [
    'Boys',
    'Girls',
    'Co-Education',
  ];

  /// Get districts for a province (sample data - should be expanded)
  static List<String> getDistrictsForProvince(String province) {
    switch (province) {
      case 'Punjab':
        return [
          'Lahore',
          'Karachi',
          'Islamabad',
          'Rawalpindi',
          'Faisalabad',
          'Multan',
          'Gujranwala',
          'Sialkot',
          'Gujrat',
          'Bahawalpur',
        ];
      case 'Sindh':
        return [
          'Karachi',
          'Hyderabad',
          'Sukkur',
          'Larkana',
          'Nawabshah',
          'Mirpur Khas',
        ];
      case 'Khyber Pakhtunkhwa (KPK)':
        return [
          'Peshawar',
          'Mardan',
          'Abbottabad',
          'Swat',
          'Kohat',
          'Bannu',
        ];
      case 'Balochistan':
        return [
          'Quetta',
          'Turbat',
          'Khuzdar',
          'Chaman',
          'Gwadar',
        ];
      default:
        return ['Select District'];
    }
  }
}

