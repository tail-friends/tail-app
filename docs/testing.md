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

Pull Request와 `develop`, `main` push에서 고정된 Flutter 버전으로 포맷,
정적 분석, 테스트와 debug APK 빌드를 수행한다. 릴리스 서명과 배포는 별도의
보호된 워크플로로 분리한다.

## 출시 전 추가 검증

- Android application ID와 버전 정책 확정
- 릴리스 서명키를 GitHub Secrets 등 보호된 저장소에 구성
- Android 라이선스 승인 및 실제 기기 smoke test
- 개인정보·사진 동의와 삭제 흐름 검증
- 스토어용 release App Bundle 빌드와 내부 테스트 트랙 확인
