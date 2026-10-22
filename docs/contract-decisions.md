# 공통 계약 결정 목록

## 상태 정의

- **CONFIRMED**: 저장소의 기존 문서에서 확인된 확정 사항이다.
- **PROPOSED**: 이번 초안에서 플랫폼 일치를 위해 제안한 규격이며 리뷰 후 확정해야 한다.
- **OPEN**: 팀 합의나 외부 정책 확인이 필요해 아직 구현 기준으로 사용할 수 없다.

상세 근거와 동작은 [인증](auth-contract.md), [사육 데이터](husbandry-data-contract.md),
[캐릭터](character-contract.md) 계약을 참조한다.

## CONFIRMED

| 영역 | 결정 | 근거 |
|---|---|---|
| 구조 | Android는 Flutter, iOS는 Swift/SwiftUI이며 동일 Spring Boot 백엔드를 사용 | [아키텍처](architecture.md) |
| 급여 | 다음 급여일 = 마지막 정상 급여일 + 급여 주기 | [아키텍처](architecture.md#핵심-도메인-경계) |
| 급여 | 급여 거부는 마지막 정상 급여일을 갱신하지 않음 | [아키텍처](architecture.md#핵심-도메인-경계) |
| 급여 | 상태는 `NO_RECORD`, `UPCOMING`, `DUE`, `OVERDUE` | [아키텍처](architecture.md#핵심-도메인-경계) |
| 캐릭터 | 속성 데이터, 행동 로직, 렌더러 분리 | [아키텍처](architecture.md#핵심-도메인-경계) |
| 캐릭터 | 행동 상태는 `IDLE`, `WALK`, `CHASE`, `EAT`, `REACT`, `SLEEP` | [아키텍처](architecture.md#핵심-도메인-경계) |
| 사진 | 원본 보관은 명시적 동의가 있는 경우에만 허용하고 삭제 경로 제공 | [아키텍처](architecture.md#보안과-사진) |
| 보안 | AI·Backend 인증키를 모바일 앱에 포함하지 않음 | [아키텍처](architecture.md#보안과-사진) |

## PROPOSED

| 영역 | 제안 | 확정 전 성격 |
|---|---|---|
| 인증 | 백엔드 사용자 식별자를 양 플랫폼 계정의 기준으로 사용 | Backend 사용자 모델 검토 필요 |
| 인증 | 앱은 제공자 UI, 서버는 credential 검증과 서비스 세션을 담당 | 제공자·서버별 세부 계약 필요 |
| 인증 | Refresh Token은 OS 보안 저장소에 보관하고 갱신 요청을 단일화 | 토큰 정책 검토 필요 |
| 인증 | 네트워크 오류와 인증 거부를 구분하며 입력·계정을 임의 삭제하지 않음 | 공통 오류 분류 필요 |
| 사육 데이터 | 정상 급여·거부를 명시적으로 구분하고 파생 상태를 재계산 | enum과 계산 주체 검토 필요 |
| 사육 데이터 | 실제 시각은 offset을 포함하고 날짜 전용 값과 구분 | 기준 시간대 검토 필요 |
| 사육 데이터 | 체중 서버 기준 단위를 gram으로 통일하고 단위를 항상 명시 | 정밀도·표시 단위 검토 필요 |
| 캐릭터 | 종·색상·무늬·체형을 안정적인 code로 표현 | code 목록과 조합 규칙 필요 |
| 캐릭터 | 서버 데이터를 기준 원본으로 하고 schema 호환성 정보를 둠 | 저장·migration 계약 필요 |
| 캐릭터 | Rive 에셋은 공유 가능하되 플랫폼별 로드·성능을 각각 검증 | 실제 에셋과 런타임 결정 필요 |

PROPOSED 항목은 PR 리뷰에서 승인되고 관련 계약에 반영되기 전까지 확정 구현 기준이 아니다.

## OPEN

| 결정해야 할 내용 | 확인 주체 | 확정 전 보류할 구현 |
|---|---|---|
| Apple/Kakao/Google 실제 지원 범위와 출시 순서 | 제품, Android, iOS, Backend | 제공자별 실제 로그인 연결과 버튼 노출 확정 |
| 제공자 credential 종류와 nonce/PKCE 등 검증 흐름 | Android, iOS, Backend | 인증 요청·응답 구현 |
| 서로 다른 제공자의 동일인 계정 연결·충돌 정책 | 제품, Backend | 자동 병합과 계정 연결·해제 UI |
| 토큰 형식·수명·회전·회수·다중 기기 정책 | Backend, Android, iOS | 세션 저장·갱신·재시도 구현 |
| 로그아웃·탈퇴 API와 삭제·유예·복구 정책 | 제품, Backend | 실제 탈퇴 실행과 완료 UI |
| 인증 및 API 오류 응답 분류와 재시도 가능 여부 | Backend, Android, iOS | 오류 코드별 분기와 자동 재시도 |
| 개체 필수 필드, 종 code, 길이와 급여 주기 범위 | 제품, Backend, Android, iOS | 등록·수정 폼 최종 검증 규칙 |
| 기록 API 필드, enum, ID, 정렬·페이지·삭제 정책 | Backend, Android, iOS | 기록 CRUD와 동기화 구현 |
| 정상 급여 상태 계산 주체와 중복·미래 기록 정책 | 제품, Backend | 서버/클라이언트 계산 구현 |
| 날짜 전용/시각 필드 구분과 다음 급여일 기준 시간대 | 제품, Backend, Android, iOS | 자정 경계와 시간대 기반 상태 구현 |
| 체중 정밀도·범위·표시 단위·반올림 | 제품, Backend | 체중 입력 검증과 변환 구현 |
| 캐릭터 JSON schema, 속성 code와 유효 조합 | 제품, Backend, Android, iOS | 캐릭터 저장·편집·동기화 구현 |
| 행동 상태 전환표·우선순위·재생 정책 | 제품, Android, iOS | 상태 기반 애니메이션 오케스트레이션 |
| Rive 파일·artboard·State Machine·input·runtime | 디자인, Android, iOS | Rive 렌더러 통합 |
| 캐릭터 schema version과 migration 책임 | Backend, Android, iOS | 렌더러 교체 호환성 구현 |
| 사진 보관 기간·동의 철회·원본/파생물 삭제 정책 | 제품, Backend, 개인정보 담당 | 원본 사진 서버 보관과 삭제 자동화 |

기존 제품·배포 미정 사항은 [확인 필요 항목](open-questions.md)에서 계속 추적한다.
