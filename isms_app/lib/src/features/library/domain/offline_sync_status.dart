
enum SyncStatus {
  synced,
  pending,
  inProgress,
  failed,
  conflict,
}

enum OfflineOperation {
  create,
  update,
  delete,
}

extension SyncStatusX on SyncStatus {
  String get dbValue {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.inProgress:
        return 'in_progress';
      case SyncStatus.failed:
        return 'failed';
      case SyncStatus.conflict:
        return 'conflict';
    }
  }

  static SyncStatus fromDb(String value) {
    switch (value) {
      case 'synced':
        return SyncStatus.synced;
      case 'pending':
        return SyncStatus.pending;
      case 'in_progress':
        return SyncStatus.inProgress;
      case 'failed':
        return SyncStatus.failed;
      case 'conflict':
        return SyncStatus.conflict;
      default:
        return SyncStatus.pending;
    }
  }
}

extension OfflineOperationX on OfflineOperation {
  String get dbValue {
    switch (this) {
      case OfflineOperation.create:
        return 'create';
      case OfflineOperation.update:
        return 'update';
      case OfflineOperation.delete:
        return 'delete';
    }
  }

  static OfflineOperation fromDb(String value) {
    switch (value) {
      case 'create':
        return OfflineOperation.create;
      case 'update':
        return OfflineOperation.update;
      case 'delete':
        return OfflineOperation.delete;
      default:
        return OfflineOperation.create;
    }
  }
}