enum AssignmentType { homework, project, worksheet, quiz, essay }

extension AssignmentTypeX on AssignmentType {
  String get dbValue {
    switch (this) {
      case AssignmentType.homework:
        return 'homework';
      case AssignmentType.project:
        return 'project';
      case AssignmentType.worksheet:
        return 'worksheet';
      case AssignmentType.quiz:
        return 'quiz';
      case AssignmentType.essay:
        return 'essay';
    }
  }

  String get displayName {
    switch (this) {
      case AssignmentType.homework:
        return 'Homework';
      case AssignmentType.project:
        return 'Project';
      case AssignmentType.worksheet:
        return 'Worksheet';
      case AssignmentType.quiz:
        return 'Quiz';
      case AssignmentType.essay:
        return 'Essay';
    }
  }

  static AssignmentType fromDb(String value) {
    switch (value) {
      case 'homework':
        return AssignmentType.homework;
      case 'project':
        return AssignmentType.project;
      case 'worksheet':
        return AssignmentType.worksheet;
      case 'quiz':
        return AssignmentType.quiz;
      case 'essay':
        return AssignmentType.essay;
      default:
        return AssignmentType.homework;
    }
  }
}

enum SubmissionStatus { notStarted, inProgress, submitted, late, graded }

extension SubmissionStatusX on SubmissionStatus {
  String get dbValue {
    switch (this) {
      case SubmissionStatus.notStarted:
        return 'not_started';
      case SubmissionStatus.inProgress:
        return 'in_progress';
      case SubmissionStatus.submitted:
        return 'submitted';
      case SubmissionStatus.late:
        return 'late';
      case SubmissionStatus.graded:
        return 'graded';
    }
  }

  String get displayName {
    switch (this) {
      case SubmissionStatus.notStarted:
        return 'Not Started';
      case SubmissionStatus.inProgress:
        return 'In Progress';
      case SubmissionStatus.submitted:
        return 'Submitted';
      case SubmissionStatus.late:
        return 'Late';
      case SubmissionStatus.graded:
        return 'Graded';
    }
  }

  static SubmissionStatus fromDb(String value) {
    switch (value) {
      case 'not_started':
        return SubmissionStatus.notStarted;
      case 'in_progress':
        return SubmissionStatus.inProgress;
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'late':
        return SubmissionStatus.late;
      case 'graded':
        return SubmissionStatus.graded;
      default:
        return SubmissionStatus.notStarted;
    }
  }
}
