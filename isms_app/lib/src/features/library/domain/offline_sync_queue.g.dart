// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineSyncQueueAdapter extends TypeAdapter<OfflineSyncQueue> {
  @override
  final int typeId = 100;

  @override
  OfflineSyncQueue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineSyncQueue(
      id: fields[0] as String,
      tableName: fields[1] as String,
      operation: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      syncStatus: fields[4] as String,
      createdAt: fields[5] as DateTime,
      schoolId: fields[10] as String,
      lastAttemptAt: fields[6] as DateTime?,
      attemptCount: fields[7] as int,
      errorMessage: fields[8] as String?,
      conflictData: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineSyncQueue obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tableName)
      ..writeByte(2)
      ..write(obj.operation)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.syncStatus)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastAttemptAt)
      ..writeByte(7)
      ..write(obj.attemptCount)
      ..writeByte(8)
      ..write(obj.errorMessage)
      ..writeByte(9)
      ..write(obj.conflictData)
      ..writeByte(10)
      ..write(obj.schoolId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineSyncQueueAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
