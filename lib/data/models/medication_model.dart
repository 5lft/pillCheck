import 'package:hive_ce/hive_ce.dart';

import '../../domain/entities/dose_time.dart';
import '../../domain/entities/medication.dart';

/// Hive 저장용 모델. 도메인 엔티티와 분리해서 저장 포맷 변경이 도메인에 새지 않게 한다.
class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.name,
    required this.memo,
    required this.timesInMinutes,
    required this.weekdays,
    required this.createdAtMillis,
  });

  factory MedicationModel.fromEntity(Medication entity) => MedicationModel(
        id: entity.id!,
        name: entity.name,
        memo: entity.memo,
        timesInMinutes: entity.times.map((t) => t.totalMinutes).toList(),
        weekdays: entity.weekdays.toList()..sort(),
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  final int id;
  final String name;
  final String memo;
  final List<int> timesInMinutes;
  final List<int> weekdays;
  final int createdAtMillis;

  Medication toEntity() => Medication(
        id: id,
        name: name,
        memo: memo,
        times: timesInMinutes.map(DoseTime.fromMinutes).toList()..sort(),
        weekdays: weekdays.toSet(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}

/// build_runner 없이 쓰는 수동 어댑터.
/// 필드를 추가할 때는 맨 뒤에 붙이고 [_version]을 올린 뒤 read에서 분기한다.
class MedicationModelAdapter extends TypeAdapter<MedicationModel> {
  static const _version = 1;

  @override
  final int typeId = 0;

  @override
  MedicationModel read(BinaryReader reader) {
    reader.readByte(); // version
    return MedicationModel(
      id: reader.readInt(),
      name: reader.readString(),
      memo: reader.readString(),
      timesInMinutes: reader.readIntList(),
      weekdays: reader.readIntList(),
      createdAtMillis: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicationModel obj) {
    writer
      ..writeByte(_version)
      ..writeInt(obj.id)
      ..writeString(obj.name)
      ..writeString(obj.memo)
      ..writeIntList(obj.timesInMinutes)
      ..writeIntList(obj.weekdays)
      ..writeInt(obj.createdAtMillis);
  }
}
