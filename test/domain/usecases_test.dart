import 'package:flutter_test/flutter_test.dart';
import 'package:pill_check/domain/entities/dose_time.dart';
import 'package:pill_check/domain/entities/medication.dart';
import 'package:pill_check/domain/exceptions/medication_exceptions.dart';
import 'package:pill_check/domain/usecases/get_adherence_summary.dart';
import 'package:pill_check/domain/usecases/get_daily_doses.dart';
import 'package:pill_check/domain/usecases/save_medication.dart';
import 'package:pill_check/domain/usecases/toggle_intake.dart';

import 'fakes.dart';

void main() {
  late FakeMedicationRepository medications;
  late FakeIntakeRepository intakes;
  late FakeReminderScheduler scheduler;
  late SaveMedication save;
  late GetDailyDoses getDailyDoses;

  // 2026-11-25 (수)
  final wednesday = DateTime(2026, 11, 25);

  Medication med(
    String name, {
    List<DoseTime> times = const [DoseTime(8, 0)],
    Set<int> weekdays = Medication.allWeekdays,
  }) =>
      Medication(
        name: name,
        times: times,
        weekdays: weekdays,
        createdAt: DateTime(2026, 11, 1),
      );

  setUp(() {
    medications = FakeMedicationRepository();
    intakes = FakeIntakeRepository();
    scheduler = FakeReminderScheduler();
    save = SaveMedication(medications, scheduler);
    getDailyDoses = GetDailyDoses(medications, intakes);
  });

  group('SaveMedication', () {
    test('저장하면 id가 발급되고 알림이 예약된다', () async {
      final saved = await save(med('혈압약'));
      expect(saved.id, isNotNull);
      expect(scheduler.scheduled, contains(saved.id));
    });

    test('이름이 공백이면 검증 예외', () async {
      await expectLater(
        save(med('   ')),
        throwsA(isA<MedicationValidationException>()),
      );
    });

    test('중복된 복용 시각은 하나로 합쳐 정렬한다', () async {
      final saved = await save(
        med(
          '비타민',
          times: const [DoseTime(20, 0), DoseTime(8, 0), DoseTime(20, 0)],
        ),
      );
      expect(saved.times, const [DoseTime(8, 0), DoseTime(20, 0)]);
    });

    test('iOS 알림 64개 제한을 넘으면 예외', () async {
      // 요일 지정(매일 아님) → 시각 6 × 요일 6 = 36개
      final heavy = med(
        'A',
        times: List.generate(6, (i) => DoseTime(6 + i * 2, 0)),
        weekdays: {1, 2, 3, 4, 5, 6},
      );
      await save(heavy);
      await expectLater(
        save(heavy.copyWith(name: 'B')),
        throwsA(isA<ReminderLimitExceededException>()),
      );
    });
  });

  group('GetDailyDoses', () {
    test('해당 요일의 약만 시간순으로 돌려준다', () async {
      await save(med('저녁약', times: const [DoseTime(19, 0)]));
      await save(med('아침약', times: const [DoseTime(8, 0)]));
      await save(med('주말약', weekdays: {6, 7}));

      final slots = await getDailyDoses(wednesday);
      expect(slots.map((s) => s.medication.name), ['아침약', '저녁약']);
    });

    test('복용 체크하면 isTaken이 바뀐다', () async {
      await save(med('혈압약'));
      final toggle = ToggleIntake(intakes);

      var slot = (await getDailyDoses(wednesday)).single;
      expect(slot.isTaken, isFalse);

      await toggle(slot);
      slot = (await getDailyDoses(wednesday)).single;
      expect(slot.isTaken, isTrue);

      await toggle(slot);
      slot = (await getDailyDoses(wednesday)).single;
      expect(slot.isTaken, isFalse);
    });
  });

  group('GetAdherenceSummary', () {
    test('아직 시각이 안 된 오늘 분은 분모에서 제외', () async {
      await save(
        med('약', times: const [DoseTime(8, 0), DoseTime(20, 0)]),
      );
      final summary = await GetAdherenceSummary(
        getDailyDoses,
        clock: () => DateTime(2026, 11, 25, 12, 0),
      )(days: 1);

      expect(summary.total, 1); // 08:00만 지남
      expect(summary.taken, 0);
    });
  });
}
