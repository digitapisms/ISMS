/// Fee frequency enum for Pakistani schools
enum FeeFrequency {
  monthly('monthly', 'Monthly'),
  quarterly('quarterly', 'Quarterly'),
  yearly('yearly', 'Yearly'),
  oneTime('one_time', 'One Time');

  const FeeFrequency(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static FeeFrequency fromDb(String value) {
    return FeeFrequency.values.firstWhere(
      (f) => f.dbValue == value,
      orElse: () => FeeFrequency.monthly,
    );
  }
}

/// Fee applicability enum
enum FeeApplicability {
  all('all', 'All Students'),
  specificClass('class', 'Specific Class'),
  section('section', 'Specific Section'),
  student('student', 'Specific Student');

  const FeeApplicability(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static FeeApplicability fromDb(String value) {
    return FeeApplicability.values.firstWhere(
      (a) => a.dbValue == value,
      orElse: () => FeeApplicability.all,
    );
  }
}
