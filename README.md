# Tail Friends (꼬리친구)

파충류 사육 기록과 2D 캐릭터 경험을 제공하는 모바일 서비스입니다.

현재 저장소는 기능 개발 전 공통 협업 환경과 Android용 Flutter 기본
프로젝트를 포함합니다. iOS 앱은 별도의 Swift/SwiftUI 담당자가
`ios-app/` 영역에서 개발하며, 백엔드는 별도 저장소에서 관리합니다.

## 저장소 구조

- `android-app/`: Flutter 기반 Android 앱
- `ios-app/`: iOS 담당 영역(현재 이 저장소에서 생성하지 않음)
- `shared/`: 플랫폼 공통 계약 및 자료
- `docs/`: 아키텍처, 협업 규칙, 테스트 문서
- `.github/`: Issue/PR 템플릿과 자동 검증 워크플로

## Android 시작하기

Flutter 3.41.7 stable을 사용합니다. FVM이 설치되어 있다면 루트의
`.fvmrc`를 기준으로 SDK를 준비할 수 있습니다.

```bash
cd android-app
flutter pub get
flutter analyze
flutter test
flutter run
```

## 협업

브랜치, 커밋, 코드 소유 영역과 리뷰 규칙은
[협업 규칙](docs/conventions.md)을 따릅니다. 테스트 범위와 CI 기준은
[테스트 전략](docs/testing.md), 구조적 결정은
[아키텍처](docs/architecture.md)를 참고하세요.

공통 UI를 구현할 때는 [디자인 시스템](docs/design-system.md)과
[컴포넌트 명세](docs/component-specs.md)를 기준으로 삼습니다. 플랫폼에서
사용하는 원본 토큰은 `shared/design-tokens.json`에 있습니다.

확정되지 않은 제품·API 항목은 [확인 필요 항목](docs/open-questions.md)에
기록합니다.
