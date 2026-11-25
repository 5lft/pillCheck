// `fvm flutter create` 직후 한 번 실행:  fvm dart run tool/patch_platforms.dart
//
// flutter_local_notifications가 요구하는 Android/iOS 네이티브 설정을 적용한다.
// 여러 번 실행해도 안전하다(이미 적용된 항목은 건너뜀).
import 'dart:io';

const appDisplayName = '약챙김';

void main() {
  _patchAndroidGradle();
  _patchAndroidManifest();
  _patchIosAppDelegate();
  _patchIosInfoPlist();
  _patchIosProject();
  stdout.writeln('\n✅ 플랫폼 설정 완료');
}

void _patchAndroidGradle() {
  final file = File('android/app/build.gradle.kts');
  if (!_exists(file)) return;
  var text = file.readAsStringSync();

  // flutter_local_notifications 23.x는 compileSdk 37 이상 필요
  text = text.replaceFirst(
    'compileSdk = flutter.compileSdkVersion',
    'compileSdk = 37',
  );

  if (!text.contains('isCoreLibraryDesugaringEnabled')) {
    text = text.replaceFirst(
      'compileOptions {',
      'compileOptions {\n        isCoreLibraryDesugaringEnabled = true',
    );
  }

  if (!text.contains('desugar_jdk_libs')) {
    text += '''

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
''';
  }

  file.writeAsStringSync(text);
  _ok(file);
}

void _patchAndroidManifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!_exists(file)) return;
  var text = file.readAsStringSync();

  if (!text.contains('POST_NOTIFICATIONS')) {
    text = text.replaceFirst(
      '<application',
      '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
          '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
          '    <application',
    );
  }

  if (!text.contains('ScheduledNotificationReceiver')) {
    text = text.replaceFirst('</application>', '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>''');
  }

  text = text.replaceFirst(
    RegExp(r'android:label="[^"]*"'),
    'android:label="$appDisplayName"',
  );

  file.writeAsStringSync(text);
  _ok(file);
}

void _patchIosAppDelegate() {
  final target = File('ios/Runner/AppDelegate.swift');
  if (!_exists(target)) return;
  File('tool/platform/AppDelegate.swift').copySync(target.path);
  _ok(target);
}

void _patchIosInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!_exists(file)) return;
  var text = file.readAsStringSync();

  text = text.replaceFirst(
    RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
    '<key>CFBundleDisplayName</key>\n\t<string>$appDisplayName</string>',
  );

  final extras = StringBuffer();
  if (!text.contains('ITSAppUsesNonExemptEncryption')) {
    // 표준 HTTPS 외 암호화 없음 → 업로드할 때마다 수출 규정 질문 생략
    extras.write(
      '\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n',
    );
  }
  if (!text.contains('CFBundleLocalizations')) {
    extras.write(
      '\t<key>CFBundleLocalizations</key>\n\t<array>\n\t\t<string>ko</string>\n\t</array>\n',
    );
  }
  if (extras.isNotEmpty) {
    final end = text.lastIndexOf('</dict>');
    text = text.substring(0, end) + extras.toString() + text.substring(end);
  }

  file.writeAsStringSync(text);
  _ok(file);
}

/// iPhone 전용으로 출시 (iPad 레이아웃·스크린샷·심사 대상에서 제외)
void _patchIosProject() {
  final file = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!_exists(file)) return;
  final text = file.readAsStringSync().replaceAll(
        'TARGETED_DEVICE_FAMILY = "1,2";',
        'TARGETED_DEVICE_FAMILY = 1;',
      );
  file.writeAsStringSync(text);
  _ok(file);
}

bool _exists(File file) {
  if (file.existsSync()) return true;
  stderr.writeln('⚠️  ${file.path} 없음 — flutter create를 먼저 실행하세요');
  return false;
}

void _ok(File file) => stdout.writeln('patched  ${file.path}');
