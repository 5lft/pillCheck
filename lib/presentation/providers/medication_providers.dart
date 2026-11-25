import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../domain/entities/medication.dart';
import 'dose_providers.dart';

/// 등록된 약 목록 + 저장/삭제 액션
final medicationsProvider =
    AsyncNotifierProvider<MedicationsNotifier, List<Medication>>(
  MedicationsNotifier.new,
);

class MedicationsNotifier extends AsyncNotifier<List<Medication>> {
  @override
  Future<List<Medication>> build() => ref.watch(getMedicationsProvider).call();

  /// 검증 실패 시 MedicationException을 그대로 던져서 화면에서 메시지를 보여준다.
  Future<void> save(Medication medication) async {
    await ref.read(saveMedicationProvider).call(medication);
    _refreshAll();
  }

  Future<void> delete(int medicationId) async {
    await ref.read(deleteMedicationProvider).call(medicationId);
    _refreshAll();
  }

  void _refreshAll() {
    ref.invalidateSelf();
    ref.invalidate(dailyDosesProvider);
    ref.invalidate(weeklyAdherenceProvider);
  }
}
