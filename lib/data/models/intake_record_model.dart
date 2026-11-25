import 'package:hive_ce/hive_ce.dart';

import '../../domain/entities/dose_time.dart';
import '../../domain/entities/intake_record.dart';

class IntakeRecordModel {
  const IntakeRecordModel({
    required this.medicationId,
    required this.dateKey,
    required this.timeInMinutes,
    required this.takenAtMillis,
  });

  factory IntakeRecordModel.fromEntity(IntakeRecord entity) =>
      IntakeRecordModel(
        medicationId: entity.medicationId,
        dateKey: dateKeyOf(entity.date),
        timeInMinutes: entity.time.totalMinutes,
        takenAtMillis: entity.takenAt.millisecondsSinceEpoch,
      );

  final int medicationId;

  /// yyyyMMdd (예: 20261125)
  final int dateKey;
  final int timeInMinutes;
  final int takenAtMillis;

  /// Hive 박스 키. 같은 약·날짜·시각은 하나만 존재한다.
  String get boxKey => boxKeyOf(medicationId, dateKey, timeInMinutes);

  static int dateKeyOf(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static String boxKeyOf(int medicationId, int dateKey, int timeInMinutes) =>
      '$medicationId-$dateKey-$timeInMinutes';

  IntakeRecord toEntity() => IntakeRecord(
        medicationId: medicationId,
        date: DateTime(dateKey ~/ 10000, dateKey % 10000 ~/ 100, dateKey % 100),
        time: DoseTime.fromMinutes(timeInMinutes),
        takenAt: DateTime.fromMillisecondsSinceEpoch(takenAtMillis),
      );
}

class IntakeRecordModelAdapter extends TypeAdapter<IntakeRecordModel> {
  static const _version = 1;

  @override
  final int typeId = 1;

  @override
  IntakeRecordModel read(BinaryReader reader) {
    reader.readByte(); // version
    return IntakeRecordModel(
      medicationId: reader.readInt(),
      dateKey: reader.readInt(),
      timeInMinutes: reader.readInt(),
      takenAtMillis: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, IntakeRecordModel obj) {
    writer
      ..writeByte(_version)
      ..writeInt(obj.medicationId)
      ..writeInt(obj.dateKey)
      ..writeInt(obj.timeInMinutes)
      ..writeInt(obj.takenAtMillis);
  }
}
