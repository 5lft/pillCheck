import 'package:pill_check/domain/entities/dose_time.dart';
import 'package:pill_check/domain/entities/intake_record.dart';
import 'package:pill_check/domain/entities/medication.dart';
import 'package:pill_check/domain/entities/reminder_response.dart';
import 'package:pill_check/domain/repositories/intake_repository.dart';
import 'package:pill_check/domain/repositories/medication_repository.dart';
import 'package:pill_check/domain/services/reminder_scheduler.dart';

class FakeMedicationRepository implements MedicationRepository {
  final _items = <int, Medication>{};
  var _lastId = 0;

  @override
  Future<List<Medication>> getAll() async => _items.values.toList();

  @override
  Future<Medication?> getById(int id) async => _items[id];

  @override
  Future<Medication> save(Medication medication) async {
    final saved =
        medication.id == null ? medication.copyWith(id: ++_lastId) : medication;
    _items[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> delete(int id) async => _items.remove(id);
}

class FakeIntakeRepository implements IntakeRepository {
  final records = <IntakeRecord>[];

  bool _same(IntakeRecord r, int medicationId, DateTime date, DoseTime time) =>
      r.medicationId == medicationId &&
      r.date.year == date.year &&
      r.date.month == date.month &&
      r.date.day == date.day &&
      r.time == time;

  @override
  Future<List<IntakeRecord>> getByDate(DateTime date) async => records
      .where(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day,
      )
      .toList();

  @override
  Future<void> save(IntakeRecord record) async {
    records
      ..removeWhere(
        (r) => _same(r, record.medicationId, record.date, record.time),
      )
      ..add(record);
  }

  @override
  Future<void> remove({
    required int medicationId,
    required DateTime date,
    required DoseTime time,
  }) async =>
      records.removeWhere((r) => _same(r, medicationId, date, time));

  @override
  Future<void> removeAllOf(int medicationId) async =>
      records.removeWhere((r) => r.medicationId == medicationId);
}

class FakeReminderScheduler implements ReminderScheduler {
  final scheduled = <int>{};

  @override
  int get maxPendingReminders => 64;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(Medication medication) async =>
      scheduled.add(medication.id!);

  @override
  Future<void> cancel(int medicationId) async => scheduled.remove(medicationId);

  @override
  Stream<ReminderResponse> get responses => const Stream.empty();
}
