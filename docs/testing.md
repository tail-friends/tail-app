# 테스트 전략

## 로컬 기본 검증

Android 변경은 `android-app/`에서 다음 순서로 확인한다.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

- 문서·템플릿만 바꾼 경우에도 YAML/Markdown 구조와 링크를 확인한다.
- 업무 규칙은 단위 테스트, 화면 동작은 Widget 테스트를 우선한다.
- 실제 API 연동은 계약이 확정된 뒤 테스트 대역과 통합 테스트 범위를 정한다.
- 실패하거나 환경상 실행하지 못한 검증은 명령과 원인을 그대로 보고한다.

## CI

모든 Pull Request와 `develop`, `main` push에서 `Flutter CI / verify` 체크를
생성한다. 변경 경로 판별 단계는 항상 실행되며 다음 파일이 바뀐 경우에만 무거운
Flutter 검증을 수행한다.

- `android-app/**`
- `.fvmrc`
- `.github/workflows/flutter-ci.yml`
- `shared/design-tokens.json`

그 외 문서나 템플릿만 변경한 경우에는 포맷·분석·테스트·APK 빌드를 건너뛰고,
건너뛴 이유를 로그에 남긴 뒤 `verify` 체크를 성공 처리한다. 변경 범위를 안전하게
계산할 수 없는 경우에는 검증을 생략하지 않고 전체 Flutter 검증을 수행한다.

Flutter 검증은 `.fvmrc`의 버전을 단일 기준으로 사용하며 JDK 17에서 아래 순서로
실행한다.

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed lib test`
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk --debug`

Flutter SDK·Pub와 Gradle 캐시를 사용하고, 같은 PR 또는 브랜치의 이전 실행은 새
실행이 시작되면 취소한다. 각 실행은 20분으로 제한한다. 릴리스 서명과 배포는 별도의
보호된 워크플로로 분리한다.

## 출시 전 추가 검증

- Android application ID와 버전 정책 확정
- 릴리스 서명키를 GitHub Secrets 등 보호된 저장소에 구성
- Android 라이선스 승인 및 실제 기기 smoke test
- 개인정보·사진 동의와 삭제 흐름 검증
- 스토어용 release App Bundle 빌드와 내부 테스트 트랙 확인
