enum ExamType {
  midTerm,
  finalExam,
  quiz,
  assignment,
  project,
  test,
}

extension ExamTypeX on ExamType {
  String get dbValue {
    switch (this) {
      case ExamType.midTerm:
        return 'mid_term';
      case ExamType.finalExam:
        return 'final';
      case ExamType.quiz:
        return 'quiz';
      case ExamType.assignment:
        return 'assignment';
      case ExamType.project:
        return 'project';
      case ExamType.test:
        return 'test';
    }
  }

  String get displayName {
    switch (this) {
      case ExamType.midTerm:
        return 'Mid-Term';
      case ExamType.finalExam:
        return 'Final';
      case ExamType.quiz:
        return 'Quiz';
      case ExamType.assignment:
        return 'Assignment';
      case ExamType.project:
        return 'Project';
      case ExamType.test:
        return 'Test';
    }
  }

  static ExamType fromDb(String value) {
    switch (value) {
      case 'mid_term':
        return ExamType.midTerm;
      case 'final':
        return ExamType.finalExam;
      case 'quiz':
        return ExamType.quiz;
      case 'assignment':
        return ExamType.assignment;
      case 'project':
        return ExamType.project;
      case 'test':
        return ExamType.test;
      default:
        return ExamType.test;
    }
  }
}

enum ExamStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

extension ExamStatusX on ExamStatus {
  String get dbValue {
    switch (this) {
      case ExamStatus.scheduled:
        return 'scheduled';
      case ExamStatus.inProgress:
        return 'in_progress';
      case ExamStatus.completed:
        return 'completed';
      case ExamStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case ExamStatus.scheduled:
        return 'Scheduled';
      case ExamStatus.inProgress:
        return 'In Progress';
      case ExamStatus.completed:
        return 'Completed';
      case ExamStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ExamStatus fromDb(String value) {
    switch (value) {
      case 'scheduled':
        return ExamStatus.scheduled;
      case 'in_progress':
        return ExamStatus.inProgress;
      case 'completed':
        return ExamStatus.completed;
      case 'cancelled':
        return ExamStatus.cancelled;
      default:
        return ExamStatus.scheduled;
    }
  }
}

enum Term {
  firstTerm,
  secondTerm,
  thirdTerm,
  annual,
}

extension TermX on Term {
  String get dbValue {
    switch (this) {
      case Term.firstTerm:
        return 'first_term';
      case Term.secondTerm:
        return 'second_term';
      case Term.thirdTerm:
        return 'third_term';
      case Term.annual:
        return 'annual';
    }
  }

  String get displayName {
    switch (this) {
      case Term.firstTerm:
        return 'First Term';
      case Term.secondTerm:
        return 'Second Term';
      case Term.thirdTerm:
        return 'Third Term';
      case Term.annual:
        return 'Annual';
    }
  }

  static Term? fromDb(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'first_term':
        return Term.firstTerm;
      case 'second_term':
        return Term.secondTerm;
      case 'third_term':
        return Term.thirdTerm;
      case 'annual':
        return Term.annual;
      default:
        return null;
    }
  }
}

