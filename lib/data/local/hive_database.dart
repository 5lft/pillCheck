import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/intake_record_model.dart';
import '../models/medication_model.dart';

/// Hive 초기화와 박스 보관. 앱 시작 시 한 번 [open]한다.
class HiveDatabase {
  HiveDatabase._(this.medications, this.intakeRecords, this._meta);

  static const _medicationsBox = 'medications';
  static const _intakeRecordsBox = 'intake_records';
  static const _metaBox = 'meta';
  static const _lastMedicationIdKey = 'last_medication_id';

  final Box<MedicationModel> medications;
  final Box<IntakeRecordModel> intakeRecords;
  final Box<dynamic> _meta;

  static Future<HiveDatabase> open() async {
    await Hive.initFlutter();
    _registerAdapter(MedicationModelAdapter());
    _registerAdapter(IntakeRecordModelAdapter());

    return HiveDatabase._(
      await Hive.openBox<MedicationModel>(_medicationsBox),
      await Hive.openBox<IntakeRecordModel>(_intakeRecordsBox),
      await Hive.openBox<dynamic>(_metaBox),
    );
  }

  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  /// 알림 id 계산에 쓰이므로 작은 정수로 순차 발급한다.
  Future<int> nextMedicationId() async {
    final last = _meta.get(_lastMedicationIdKey, defaultValue: 0) as int;
    final next = last + 1;
    await _meta.put(_lastMedicationIdKey, next);
    return next;
  }
}
