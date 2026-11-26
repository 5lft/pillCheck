# 약챙김 (pill_check)

약 먹을 시간을 알려주고 복용 기록을 남기는 Flutter 복약 알림 앱.

- **Flutter** 3.50.1 stable (FVM으로 고정)
- **상태 관리** Riverpod 3 (코드 생성 없이 `Notifier` / `AsyncNotifier`)
- **로컬 DB** Hive CE (수동 TypeAdapter, build_runner 불필요)
- **알림** flutter_local_notifications 23 (반복 알림 + "복용 완료" 액션 버튼)
- **아키텍처** Clean Architecture: `app` / `data` / `domain` / `presentation`

## 빠른 시작

```bash
chmod +x setup.sh
./setup.sh          # FVM 설치 → Flutter 3.50.1 → flutter create → 네이티브 패치 → analyze/test
fvm flutter run
```

`setup.sh`가 하는 일:

1. FVM이 없으면 Homebrew로 설치
2. `.fvmrc`에 적힌 Flutter 3.50.1 설치 후 이 프로젝트에 고정 (`.fvm/flutter_sdk` 링크 생성)
3. `fvm flutter create --org com.jua .`로 `ios/`, `android/` 폴더 생성 (기존 `lib/`는 그대로)
4. `tool/patch_platforms.dart`로 알림에 필요한 네이티브 설정 적용
   - Android: `compileSdk 37`, core library desugaring, 알림 권한, 알림 receiver
   - iOS: `AppDelegate`에 알림 delegate 등록, 표시 이름, 암호화 수출 규정(`ITSAppUsesNonExemptEncryption=false`)

> VS Code는 `.vscode/settings.json`이 `.fvm/flutter_sdk`를 가리키도록 설정돼 있어요.
> Android Studio는 Settings → Languages & Frameworks → Flutter → SDK path를 `<프로젝트>/.fvm/flutter_sdk`로 지정하세요.

## 구조

```
lib/
├── main.dart
├── app/                         # 조립(Composition root)
│   ├── bootstrap.dart           # Hive·알림 초기화 → ProviderScope override
│   ├── app.dart                 # MaterialApp, 한국어 로케일
│   ├── di/providers.dart        # Repository / UseCase Provider
│   └── theme/app_theme.dart
├── domain/                      # 순수 Dart. Flutter·Hive 의존 없음
│   ├── entities/                # Medication, DoseTime, DoseSlot, IntakeRecord ...
│   ├── repositories/            # 추상 인터페이스
│   ├── services/                # ReminderScheduler 인터페이스
│   ├── usecases/                # SaveMedication, GetDailyDoses, ToggleIntake ...
│   └── exceptions/
├── data/                        # 구현
│   ├── local/hive_database.dart
│   ├── models/                  # Hive 모델 + TypeAdapter
│   ├── datasources/
│   ├── repositories/            # *RepositoryImpl
│   └── services/                # LocalNotificationReminderScheduler
└── presentation/
    ├── providers/               # 화면 상태 (AsyncNotifier, family)
    ├── pages/                   # 오늘 / 내 약 / 기록 / 약 등록·수정
    └── widgets/
test/domain/                     # UseCase 단위 테스트 (Fake 리포지토리)
```

의존 방향: `presentation → domain ← data`, `app`이 둘을 연결한다.
presentation은 `app/di`에서 UseCase만 꺼내 쓰고 data 구현체를 모른다.

## 설계 메모

- **iOS 로컬 알림 64개 제한**: 날짜마다 예약하지 않고 `matchDateTimeComponents`로 반복 알림을 건다.
  매일 복용은 시각당 1개(`time`), 요일 지정은 시각×요일(`dayOfWeekAndTime`).
  `SaveMedication`에서 전체 필요 개수를 계산해 64개를 넘으면 저장을 막는다.
- **알림 id**: `medicationId * 100 + timeIndex * 10 + weekday` → 약 단위로 찾아서 취소 가능.
- **알림 액션**: "복용 완료"를 누르면 앱이 열리면서 `ReminderScheduler.responses` 스트림으로 전달되고
  `MarkDoseTaken`이 기록한다. 콜드 스타트 시 탭 이벤트도 단일 구독 스트림이 버퍼링한다.
- **권한 요청 시점**: 앱 첫 실행이 아니라 첫 약 저장 시 요청.
- **Android 정확도**: 정확한 알람 권한 없이 `inexactAllowWhileIdle` 사용 (몇 분 오차 가능).
- **Hive**: 원본 `hive`는 유지보수 중단 상태라 커뮤니티판 `hive_ce` 사용.
  어댑터는 수동 작성 (필드 추가 시 맨 뒤에 붙이고 버전 바이트로 분기).

## 앱스토어 제출 체크리스트

등록 문구·심사 메모·개인정보 응답은 `store/app_store_listing.md`에 정리돼 있다.

- [ ] Apple Developer 가입 승인
- [ ] Xcode → Runner → Signing & Capabilities에서 Team 선택, Bundle ID 확인
- [x] 앱 아이콘 1024×1024 — `python3 tool/make_app_icon.py`로 생성
- [x] iPhone 전용 설정 (`TARGETED_DEVICE_FAMILY = 1`, patch_platforms.dart)
- [ ] App Store Connect에서 앱 생성 → 카테고리 "건강 및 피트니스"
- [x] 개인정보처리방침 URL — https://5lft.github.io/pillCheck/privacy/ (GitHub Pages, `main` 브랜치 `/docs`)
- [x] App Privacy 응답 정리: "데이터를 수집하지 않음"
- [x] 스크린샷 6.9인치 5장 — `store/screenshots/`
- [x] Release 빌드 확인 (`fvm flutter build ios --release --no-codesign`)
- [ ] `fvm flutter build ipa` → Transporter로 업로드
- [ ] TestFlight 실기기에서 알림·"복용 완료" 동작 확인 후 심사 제출
