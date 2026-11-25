import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/intake_local_data_source.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/local/hive_database.dart';
import '../../data/repositories/intake_repository_impl.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/repositories/intake_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/services/reminder_scheduler.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/get_adherence_summary.dart';
import '../../domain/usecases/get_daily_doses.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/mark_dose_taken.dart';
import '../../domain/usecases/save_medication.dart';
import '../../domain/usecases/toggle_intake.dart';

// 조립(Composition root). presentation은 여기서 use case만 꺼내 쓰고
// data 계층 구현체는 직접 알지 못한다.

// ── 비동기 초기화가 필요한 인프라: bootstrap에서 override ──
final hiveDatabaseProvider = Provider<HiveDatabase>(
  (ref) => throw UnimplementedError('bootstrap에서 override 해야 합니다'),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => throw UnimplementedError('bootstrap에서 override 해야 합니다'),
);

// ── Repositories ──
final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(
    MedicationLocalDataSource(ref.watch(hiveDatabaseProvider)),
  ),
);

final intakeRepositoryProvider = Provider<IntakeRepository>(
  (ref) => IntakeRepositoryImpl(
    IntakeLocalDataSource(ref.watch(hiveDatabaseProvider)),
  ),
);

// ── Use cases ──
final getMedicationsProvider = Provider(
  (ref) => GetMedications(ref.watch(medicationRepositoryProvider)),
);

final saveMedicationProvider = Provider(
  (ref) => SaveMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);

final deleteMedicationProvider = Provider(
  (ref) => DeleteMedication(
    ref.watch(medicationRepositoryProvider),
    ref.watch(intakeRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);

final getDailyDosesProvider = Provider(
  (ref) => GetDailyDoses(
    ref.watch(medicationRepositoryProvider),
    ref.watch(intakeRepositoryProvider),
  ),
);

final toggleIntakeProvider = Provider(
  (ref) => ToggleIntake(ref.watch(intakeRepositoryProvider)),
);

final markDoseTakenProvider = Provider(
  (ref) => MarkDoseTaken(
    ref.watch(medicationRepositoryProvider),
    ref.watch(intakeRepositoryProvider),
  ),
);

final getAdherenceSummaryProvider = Provider(
  (ref) => GetAdherenceSummary(ref.watch(getDailyDosesProvider)),
);
