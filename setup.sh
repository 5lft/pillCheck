#!/usr/bin/env bash
# 약챙김 프로젝트 초기 세팅 (macOS)
#   chmod +x setup.sh && ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

FLUTTER_VERSION=$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' .fvmrc)

if ! command -v fvm >/dev/null 2>&1; then
  echo "▶ FVM 설치 (Homebrew)"
  brew tap leoafarias/fvm
  brew install fvm
fi

echo "▶ Flutter $FLUTTER_VERSION 설치 및 프로젝트에 고정"
fvm install "$FLUTTER_VERSION"
fvm use "$FLUTTER_VERSION" --force

echo "▶ iOS/Android 네이티브 폴더 생성 (기존 lib/ 파일은 덮어쓰지 않음)"
fvm flutter create \
  --org com.jua \
  --project-name pill_check \
  --platforms ios,android \
  .

# flutter create가 만든 기본 카운터 위젯 테스트는 이 앱과 맞지 않으므로 제거
rm -f test/widget_test.dart

echo "▶ 패키지 설치"
fvm flutter pub get

echo "▶ 알림용 네이티브 설정 적용"
fvm dart run tool/patch_platforms.dart

echo "▶ 정적 분석 / 테스트"
fvm flutter analyze || echo "⚠️  analyze 결과를 확인하세요"
fvm flutter test || echo "⚠️  테스트 결과를 확인하세요"

echo
echo "완료! 실행:  fvm flutter run"
