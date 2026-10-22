# Tail Friends 디자인 시스템

## 기준과 범위

- Figma 파일: `FpS23pMGjJtXRj0AYVMSDK`
- Foundations: `0:1`
- Components: `4:2`
- 기본 테마: Mist(라이트)
- 공통 토큰: `shared/design-tokens.json`
- Android 구현: `android-app/lib/core/design_system/`

Figma의 `tail/primitive`, `tail/color`, `tail/dimension` 컬렉션 관계를 따라
원시값과 의미별 별칭을 분리한다. MCP에서 primitive 변수의 원래 이름은
노출되지 않아 저장소의 primitive 키는 색상값 기반으로 표기했고, semantic
키는 Figma 이름을 그대로 유지했다. 다크 모드는 Figma에 확인된 값이 없어
정의하지 않는다.

## 색상

| 의미 토큰 | 값 |
|---|---:|
| `bg/canvas` | `#F4F2EE` |
| `bg/surface` | `#FBFAF8` |
| `bg/sunken` | `#ECE9E3` |
| `bg/primary` | `#1E1C1A` |
| `bg/primary-soft` | `#EFE9DF` |
| `text/primary` | `#1E1C1A` |
| `text/secondary` | `#8C857A` |
| `text/tertiary` | `#ABA498` |
| `text/on-primary` | `#FBFAF8` |
| `text/accent` | `#8C7656` |
| `text/success` | `#66705A` |
| `text/warning` | `#93733D` |
| `text/danger` | `#B0705F` |
| `border/default` | `#DEDAD2` |
| `border/strong` | `#ABA498` |

컴포넌트 컨텍스트에서 `text/component-primary`(`#3B3631`), 상태별 soft
배경과 아이콘 색상이 추가 확인됐다. 버튼과 일부 카드의 그라디언트는 단일
semantic 색상을 대체하지 않고 컴포넌트 스타일로 관리한다.

## 크기

- Spacing: 4, 8, 12, 16, 20, 24, 32, 40
- Radius: sm 8, md 12, lg 18, xl 24, full 999
- 기본 콘텐츠 너비: 342px(390px 화면에서 좌우 24px)
- 버튼: 최소 높이 50px
- 입력 필드: 최소 높이 48px
- 하단 내비게이션: 최소 높이 54px

컴포넌트는 Figma 높이를 최소 높이로 구현한다. 시스템 글자 크기가 커지면
텍스트를 잘라내는 대신 필요한 만큼 세로로 확장한다.

## Typography

폰트는 Gowun Dodum Regular 한 종류다. 글꼴이 제공하지 않는 굵기를
인위적으로 합성하지 않기 위해 모든 스타일은 Regular(400)를 사용한다.

| 스타일 | 크기 / 줄 높이 |
|---|---:|
| Display/Large | 24 / 32 |
| Display/Medium | 19 / 26 |
| Title/Large | 16 / 22 |
| Title/Medium | 14 / 20 |
| Body/Strong | 13 / 19 |
| Body/Regular | 13 / 19 |
| Label/Medium | 12 / 16 |
| Caption/Regular | 11 / 14 |
| Number/Large | 28 / 32 |
| Wordmark | 16 / 20 |
| Overline | 11 / 14 |

Gowun Dodum은 SIL Open Font License 1.1로 배포된다. 앱과 함께 번들·재배포할
수 있으며, 저작권 고지와 라이선스를 유지해야 한다. 공식 글꼴과
`assets/licenses/GowunDodum-OFL.txt`를 함께 포함한다.

## 플랫폼 공통 규칙

- Android와 iOS는 `shared/design-tokens.json`을 단일 규격으로 사용한다.
- 의미별 토큰을 UI 코드에서 사용하고 원시 색상을 화면에 반복하지 않는다.
- 터치 대상은 최소 44×44 논리 픽셀을 확보한다.
- 색상만으로 상태를 구분하지 않고 텍스트·선택 의미를 함께 제공한다.
- 로딩 중에는 중복 동작을 차단하고 접근성 레이블로 진행 상태를 알린다.
- 소셜 로그인 노출 순서와 플랫폼 정책은 인증 기능 Issue에서 결정한다.
- 확인되지 않은 dark mode, 오류·pressed·hover 시각값은 임의로 공통 토큰화하지 않는다.

## Flutter 적용

`AppTheme.mist`를 `MaterialApp.theme`에 지정한다. Flutter 구현은 Figma의
그라디언트와 glass blur를 재현하되, 플랫폼 기본 포커스·키보드·접근성
동작은 유지한다. 개발 빌드에서만 기본 화면의 “디자인 시스템 미리보기”로
컴포넌트 카탈로그에 진입할 수 있다.
