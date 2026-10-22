# Tail Friends Android

Tail Friends의 Android용 Flutter 애플리케이션입니다. 현재는 기능 개발 전
실행 가능한 기본 화면, 공통 디자인 시스템과 자동 검증을 포함합니다.

## 요구 환경

- Flutter 3.41.7 stable
- Dart 3.11.5
- Android SDK 36.1
- JDK 21(Android Studio 내장 JDK 사용 가능)

저장소 루트의 `.fvmrc`와 CI가 동일한 Flutter 버전을 사용합니다.

## 검증

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

프로젝트 규칙은 [AGENTS.md](AGENTS.md), 전체 구조와 협업 규칙은 저장소의
`docs/` 문서를 참고하세요.

디버그 빌드에서는 기본 화면의 `디자인 시스템 미리보기` 버튼으로 공통
컴포넌트 카탈로그를 확인할 수 있습니다. 릴리스 빌드에는 이 진입점이
노출되지 않습니다.
