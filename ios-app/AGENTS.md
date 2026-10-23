# iOS 작업 규칙

## 범위와 구조

- iOS 코드는 이 디렉터리 안에서 Swift와 SwiftUI로 작성한다. 공통 구조와 제품 결정은 저장소 루트의 `AGENTS.md`, `docs/architecture.md`, `docs/conventions.md`를 따른다.
- 최소 배포 대상은 iOS 17이며 Swift 언어 모드는 프로젝트 설정인 Swift 5를 유지한다. Apple SDK만 사용하고 새 패키지 의존성은 해당 Issue에서 필요성을 확인한다.
- 앱 진입점은 `TailFriends/App/`, 기능별 화면과 상태는 `TailFriends/Features/`, 내비게이션·네트워크·저장은 각각 `TailFriends/Core/Navigation/`, `TailFriends/Core/Network/`, `TailFriends/Core/Storage/`, 리소스는 `TailFriends/Resources/`에 둔다.
- 공용 UI 구성요소나 새 추상화는 둘 이상의 확정된 사용처가 생길 때 추가한다. 현재 부트스트랩 단계에서는 기본 화면과 폴더 경계만 유지한다.

## 제품 및 보안 경계

- 승인된 요구사항과 API 계약이 없으면 제품 화면, 인증 흐름, 네트워크 동작, 저장 동작, 모델·필드·업무 규칙을 추측해 구현하지 않는다.
- 앱에 비밀번호, 토큰, 서명 키 또는 백엔드·AI 인증 키를 넣지 않는다. 민감한 정보는 로그와 테스트 결과에도 출력하지 않는다.
- 원본 사진 보관과 권한 요청은 목적, 동의, 삭제 흐름이 확정된 Issue에서만 구현한다.

## Swift와 검증

- SwiftUI 뷰는 화면 표시와 사용자 상호작용에 집중시키고, 미확정 업무 규칙이나 데이터 접근을 추가하지 않는다. 접근성 식별자가 필요한 UI는 명시적인 안정된 식별자를 둔다.
- 동작 변경은 기존 `TailFriendsTests` 또는 `TailFriendsUITests`에서 관찰 가능한 결과를 검증한다. 테스트를 실행하지 못한 경우 성공으로 보고하지 않고 환경 오류를 기록한다.
- 저장소의 `docs/testing.md`와 `ios-app/README.md`에 적힌 `xcodebuild` 명령으로 빌드와 시뮬레이터 테스트를 확인한다. 시뮬레이터 검증은 구체적인 기기 대상과 실제 결과를 보고한다.
