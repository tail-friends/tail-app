# 공통 컴포넌트 명세

## Button (`4:10`)

- 용도: 주요·보조·저강도 행동
- 크기: 너비는 부모에 맞춤, 최소 높이 50, radius full
- 글꼴: Title/Medium, Primary는 `text/on-primary`, 나머지는 component primary
- Variant: Primary, Secondary, Ghost
- 상태: 기본은 Figma 확인. disabled와 loading은 Flutter 구현 상태이며 opacity와 진행 표시로 구분
- 공통 동작: disabled/loading 중 입력 차단, 버튼 의미와 진행 상태를 접근성에 제공

## Button/Social (`4:26`)

- 용도: Apple, Kakao, Google 인증 진입
- 크기: 최소 높이 50, 아이콘 18, 간격 8, radius full
- 색상: Apple `#3B3631`, Kakao `#FEE500`, Google white + border/default
- 글꼴: Title/Medium
- Variant: Apple, Kakao, Google
- 상태: Figma는 기본만 확인. 실제 인증 연결과 플랫폼 노출 정책은 후속 작업
- 공통 동작: 제공자명을 포함한 접근성 레이블, 로고는 장식 이미지로 처리

## Chip (`4:37`)

- 용도: 짧은 상태 표시
- 크기: 좌우 10, 상하 4, radius full
- 글꼴: Caption/Regular
- Variant: Success, Warning, Danger, Accent, Neutral
- 색상: 각 semantic text/soft background 조합
- 공통 동작: 단독 색상 대신 의미 있는 레이블을 항상 표시

## Speech Bubble (`4:38`)

- 용도: 캐릭터의 짧은 상태 메시지
- 크기: 좌우 12, 상하 6, radius full
- 색상: 흰색 glass gradient, 흰색 border, component primary 텍스트
- 글꼴: Label/Medium
- 상태: 단일 기본 상태
- 공통 동작: 장식 말풍선이어도 메시지는 스크린 리더가 읽을 수 있어야 함

## TabBar/Glass (`14:111`)

- 용도: 사육장·기록·내 아이들·마이의 최상위 이동
- 크기: 너비 최대 342, 최소 높이 54, 좌우 10, 탭 간격 8, 탭 최소 높이 38, 아이콘 16
- 색상: glass gradient, 활성 탭 bg/surface, 비활성 text/icon tertiary
- Variant: Active=사육장, 기록, 내 아이들, 마이
- 상태: 현재 탭 selected, 나머지 unselected
- 공통 동작: Figma의 38px 선택 capsule 외형을 유지하면서 각 탭의 실제 터치
  영역은 최소 44×44px로 확장한다. 선택 상태와 탭 의미를 접근성에 제공하며
  실제 라우팅은 화면 기능에서 연결한다.

## Row/Record (`4:121`)

- 용도: 최근 사육 기록 한 건 표시
- 크기: 기준 높이 64, 상하 14, 요소 간격 14, icon badge 34, icon 16
- 색상: glass icon badge, 제목 component primary, 메타 secondary, trailing tertiary
- 글꼴: Body/Regular, Caption/Regular, Label/Medium
- 상태: 기본 및 선택 가능한 행
- 공통 동작: 행 전체가 한 개의 터치·접근성 대상으로 동작하며 텍스트는 말줄임 허용

## TextField (`4:131`)

- 용도: 개체 등록 등 짧은 텍스트 입력
- 크기: 최소 높이 48, 좌우 16, label gap 8, radius md
- 색상: glass surface, label secondary, hint tertiary, error danger
- 글꼴: Label/Medium 및 Body/Regular
- 상태: 기본, focused(플랫폼 포커스), error, disabled
- 공통 동작: label은 hint와 별도로 유지한다. 입력 제한·키보드 타입을 호출자가
  제공하고 오류를 텍스트로 알린다. `showCounter`를 선택하면 개체 등록 화면
  (`31:2984`)처럼 현재 글자 수/최대 글자 수를 우측 하단에 표시한다.

## AppCard (화면 참조 `15:410`, `32:2898`)

- 용도: 홈 hero, 지표, 최근 기록과 개체 정보 그룹의 공통 glass surface
- 크기: 화면에 따라 radius xl(24), padding은 콘텐츠가 결정
- 색상: 반투명 white gradient, white border, warm shadow
- 상태: 기본. 카드 자체 클릭은 선택 사항이며 클릭 시 전체 카드가 단일 동작 대상
- 공통 동작: 업무별 레이아웃은 카드 내부에서 구성하고 AppCard에 과도한 속성을 추가하지 않는다.

## 자산과 플랫폼

소셜, 탭, 기록 아이콘은 Figma 원본 SVG를 Android asset으로 사용한다. iOS는
동일한 Figma Node ID와 18/16px 규격을 기준으로 별도 자산 파이프라인에
추가한다. Android 구현은 Flutter의 `flutter_svg`를 사용하며 임시 Figma URL을
런타임에 참조하지 않는다.
