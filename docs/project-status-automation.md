# 디자인·API 개발 현황 자동화

## 구성

- `project-status/data/designs.json`: Figma `App · MVP`의 추적 대상 89개 화면·상태
- `project-status/data/api-tasks.json`: 확정된 OpenAPI 작업만 등록하는 API 목록
- `.github/scripts/project_status.py`: Merge 메타데이터 집계, Figma 버전 비교, JSON/XLSX 생성
- `project-status/site/`: GitHub Pages 정적 웹 현황표
- `.github/workflows/project-status.yml`: Merge·수동·정기·Figma Webhook 동기화
- `integrations/figma-webhook/`: 선택적으로 배포하는 외부 HTTPS 수신기

오류·권한 오버레이 9개는 별도 공통 상태이므로 사용자 요청의 89개 추적 분모에서 제외했다.
중첩 레이어는 화면으로 집계하지 않는다.

## 진행률 규칙

UI 진행률의 분모는 플랫폼별 89개 디자인이다. `complete`만 완료로 계산하며
`partial`, `not_started`, `needs_confirmation`, 디자인 변경 후 `review_required`는
완료율을 올리지 않는다. Figma 변경은 UI 재검토만 표시하며 API 상태를 바꾸지 않는다.

UI 완료는 Figma 화면·필요한 상호작용·시각 비교·관련 Widget/UI 테스트에 대한
명시적 완료 확인, 검증한 현재 PR HEAD 전체 SHA, develop Merge가 모두 확인된
범위다. API 호출·DB 저장·사진 업로드·AI 연동이 없는 것은 UI 미완료 사유가 아니다.
Debug 미리보기만 구현한 UI도 이 조건을 충족하면 완료할 수 있으며 범위/비고에
Debug 전용과 실제 데이터 미연동을 명시한다. UI 완료는 서비스 기능 동작 보장이 아니다.

API 진행률의 분모는 `api-tasks.json`에 명세 근거와 함께 등록된 작업만 사용한다.
목록이 비어 있는 현재는 `0%`가 아니라 `집계 준비 중`으로 표시한다. Backend 구현과
Android/iOS 연동 상태는 `integration.android`, `integration.ios`로 분리한다.

초기 Android 완료 이력은 실제 develop Merge로 확인된 PR #20(01 로그인),
PR #24(02 홈), PR #22(03 개체 등록), PR #29(03-4 종 선택)이다. PR #29의 Merge
커밋은 `5a894d7`이며 Issue #28과 Merge 시각을 03-4 레지스트리에 기록한다.

## PR 메타데이터

PR 생성·수정 시 `PR 개발 현황 메타데이터` 워크플로가 아래 블록을 자동으로
생성하거나 갱신한다. 개발자가 블록 코드를 작성할 필요는 없다. 기존의 정확한 수동
블록은 공백·문구까지 그대로 보존한다. 다음 예시는 형식 설명용이다.

```text
tail-status
figma_numbers: 03, 03-0
work_type: UI
platforms: Android
completed_scope: 개체 등록 기본 화면과 필수 입력 상태
completed: true
api_work_ids:
design_version: 123456789
design_review: implemented
```

- `figma_numbers`: 여러 값은 쉼표로 구분한다.
- `work_type`: `UI`, `API`, `OTHER`만 허용한다.
- `platforms`: `Android`, `iOS`를 쉼표로 구분한다.
- `completed_scope`: 실제 완료 범위를 적는다.
- `completed`: UI에서는 UI 퍼블리싱, API에서는 등록 API 작업 연동의 완료 선언이다.
  새 완료 집계에는 해당 범위의 본문 검증·승인과 현재 HEAD 전체 SHA도 확인한다.
  이미 완료된 초기/이전 현황 이력은 이 규칙 도입으로 되돌리지 않는다.
- `api_work_ids`: API 작업일 때 등록된 ID를 적는다.
- `design_version`: 디자인 변경 검토를 끝낸 Figma version ID다.
- `design_review`: `implemented` 또는 `no_changes_needed`만 허용한다.

`develop`에 실제 Merge된 PR만 읽는다. 번호가 없거나 레지스트리에 없는 번호가 있으면
해당 PR 전체를 완료 처리하지 않고 확인 목록에 남긴다. `main` 릴리스 PR은 조회 대상이
아니므로 중복 집계되지 않는다. Merge 집계기는 PR 제목으로 완료 여부를 판정하지 않는다.

### 자동 입력과 완료 확인

- 공통 규칙: `.github/scripts/pr_metadata.py`. Python 표준 라이브러리만 사용한다.
- 대상: `develop`, `main`을 향하는 열린 PR. 생성, 본문/제목 수정, 새 커밋,
  재개방, Draft 전환·해제 시 실행한다.
- 연결 Issue: GitHub GraphQL `closingIssuesReferences`와 본문의 동일 저장소
  `Closes/Fixes/Resolves #번호` 또는 Issue URL을 읽는다. 일반 참고용 Issue 번호나
  다른 저장소 Issue는 자동 연결하지 않는다. Issue 조회 실패 시 본문을 수정하지 않는다.
- 화면 번호: PR/연결 Issue 제목의 명시적 Figma 번호, PR/Issue의 `Figma 번호:`
  항목, 해당 Figma 파일의 node URL을 레지스트리와 대조한다. 단순 숫자·화면 크기,
  코드 예시에서 번호를 추측하지 않는다. 미등록 값은 입력하지 않고 확인 안내를 남긴다.
  PR의 명시적 `Figma 번호` 항목을 우선하고, 그다음 PR 제목·node URL,
  마지막으로 연결 Issue를 사용해 참고 화면이나 Issue 전체 범위를 과잉 추가하지 않는다.
- 플랫폼: 실제 `android-app/`, `ios-app/` 변경 경로가 근거다. Issue 제약 문구에
  다른 플랫폼이 언급됐다는 이유로 플랫폼을 추가하지 않는다.
- 종류: presentation/features/View 경로는 UI 후보, data/api/network/repositories/services
  경로 또는 등록 API ID는 API 후보다. UI/API 혼합이면 `OTHER`로 보류하고
  PR의 `작업 종류: UI` 또는 `API`와 실제 완료 범위로 집계 범위를 선택할 수 있다.
  이 분류는 코드 의미를 분석한 증명이 아닌 후보 추론이다.
- API: `api-tasks.json`에 실제 등록된 ID만 사용한다. 현재 목록이 비어 있으므로
  API 작업 ID를 만들지 않는다. 화면·API 대상이 불명확하면 `OTHER / false`로
  두고 누락된 근거만 안내한다.
- 기존 유효한 수동 블록의 완료 표시는 작성자 선언으로 보존한다. 레지스트리,
  파일 플랫폼, 확인된 화면과 충돌하는 블록은 다시 생성하고 완료 여부를 재확인한다.

자동 생성 값은 기본적으로 `completed: false`다. 검증한 UI/API 범위를 완료로
확인하려면 PR의 일반 텍스트 항목을 다음처럼 작성한다. 블록 코드는 수정하지 않는다.

```text
- Figma 번호: 01-1
- 작업 종류: UI
- 완료 범위: 개인정보 동의 바텀시트와 필수 체크 동작
- 완료 여부: 완료
- 완료 근거: 해당 범위 Widget 테스트와 에뮬레이터 시각 확인 완료
- 완료 검증 커밋: 검증한 현재 PR HEAD의 전체 40자리 SHA
- API 작업 ID:
```

일반 항목과 하위 호환되며, 작업 종류별로 다음 이름을 사용할 수도 있다.
같은 항목에 종류별 값이 있으면 그 값을 우선한다. `UI 퍼블리싱 완료 여부: 완료`와
`API 연동 완료 여부: 미완료`를 함께 써도 UI만 집계하는 PR의 완료를 막지 않는다.

```text
- 작업 종류: UI
- UI 퍼블리싱 완료 여부: 완료
- UI 퍼블리싱 완료 범위: Debug 체중 시트의 키패드·탭 전환·측정 시각 UI
- UI 퍼블리싱 완료 근거: Figma 시각 비교와 키패드·탭 전환 Widget 테스트, 검토 승인 완료
- UI 퍼블리싱 완료 검증 커밋: 검증한 현재 PR HEAD의 전체 40자리 SHA
- API 연동 완료 여부: 미완료
```

API PR은 `API 연동 완료 여부/완료 범위/완료 근거/완료 검증 커밋`을 사용한다.
실제 명세·연동·검증 근거가 필요하며 등록되지 않은 API 작업은 분모나 완료에 넣지 않는다.
위 예시의 완료 선언은 작성법 설명이며 과거 PR에 대한 승인으로 사용하지 않는다.

현재 HEAD SHA, 범위·근거·명시적 완료 선언이 모두 있어야 하며 Draft·미등록 번호·
혼합 범위 미확정 상태에서는 자동 완료가 되지 않는다. 단순 `CI 성공`, `PR Merge`는
완료 근거로 인정하지 않는다. 새 커밋이 추가되어 검증 커밋과 달라지면 자동 완료를
해제한다. 이 근거는 사람의 검증 선언이지 자동화가 기능·법적 정책을 승인한 것은 아니다.
디자인 버전 및 `design_review` 승인 값은 자동 추정하지 않는다.
필요한 경우 일반 본문에 `디자인 버전: 실제 version ID`와
`디자인 검토: implemented` 또는 `no_changes_needed`를 명시해 자동 블록에 전달한다.
현재 디자인 버전과 일치하고 해당 UI의 검증·완료가 확인된 경우에만 재검토를 해제한다.

기존 유효한 수동 블록은 계속 보존한다. 다만 블록의 true만으로 새로운 완료를
만들지는 않으며, 검증 근거 없는 새 완료 요청은 확인 목록에 남긴다. 기존 false
블록이 남은 Merge PR도 본문에 해당 범위의 완료·검증·현재 HEAD를 명시하면 재집계할 수
있다. 이전 완료 상태는 나중의 부분 작업이나 근거 누락으로 하향하지 않는다.

## 과거 PR 재집계와 데이터 보존

집계는 이전 상태를 초기 레지스트리에 병합한 뒤 develop Merge PR의 현재 본문을
다시 평가한다. `related_prs`에 있는 번호도 건너뛰지 않는다. PR/Issue 연결·실제 Merge
시각·완료 범위 메모·반영 버전·Figma 재검토 상태·등록된 API 연동 이력을 보존한다.
새 API를 등록해도 기존 API 완료 상태를 초기화하지 않으며, 이전 데이터에만 남은
미등록 API를 임의로 다시 등록하지 않는다. PR별 완료 증빙은 `completion_history`에
보존한다. 재집계로 바뀐 본문과 과거 완료 기록은 별도로 보존한다.

동일 PR의 연결/이력은 중복 추가하지 않고, 완료율은 PR 수가 아닌 화면/작업 상태로
계산한다. PR Merge 알림은 기존 `applied_prs`와 추가 `notification_events`로 재전송을
막으며, 수동 재집계는 별도의 Merge 알림을 만들지 않는다. Discord 발송이 실패했을 때의
재전송 보장은 기존과 같이 상태 artifact 보존/발송 간 순서에 영향을 받으므로 운영 확인이
필요하다. 성공했다고 확인되지 않은 실제 전송을 코드 테스트로 대신하지 않는다.

명시적 검증이 없는 false를 일괄 true로 바꾸지 않는다. #58은 확인된 증빙으로 UI 완료,
#52/#54/#60/#62/#65/#68은 현재 본문의 확인 대기 상태를 유지하는 읽기 전용 fixture를
`.github/scripts/tests/fixtures/progress-prs-70.json`에 기록했다. 이 fixture는 추적 필드
발췌본이며 실제 PR 본문을 변경하지 않는다.

로컬 읽기 전용 절차(생성 파일은 build 아래에만 기록):

```bash
python .github/scripts/project_status.py build --repository tail-friends/tail-app \
  --github-fixture <GitHub에서-GET으로-읽은-Merge-PR-JSON> \
  --previous-status <현재-Pages의-status.json> \
  --output build/project-status-preview --dry-run
```

토큰을 환경에 안전하게 설정한 경우 `--github-fixture`를 생략하면 GitHub의 GET 조회만
실행한다. `--dry-run`은 로컬 현황·XLSX를 생성하고 notification.kind를 none으로 만든다.
GitHub API 본문 수정·Pages 배포·Discord 발송은 하지 않는다. 이전 현황을 누락한 채
운영 재집계를 시작하지 않는다. 활성화된 워크플로에서는 이전 artifact와 Pages 모두
읽을 수 없으면 이력 초기화를 막기 위해 실패 처리한다.

승인된 워크플로 배포 후 Actions → 개발 현황 갱신 → Run workflow에서 `dry_run=true`를
선택하면 `project-status-preview-실행번호` artifact만 생성한다. Pages 설정·배포 및
정상 상태 artifact 교체·Discord 발송은 건너뛴다. 결과 검토 후 배포 승인된 실행에서만
false로 실행한다. 기존 수동 배포와의 호환성을 위해 입력 기본값은 false다.

### 본문 보존·중복 방지·보안

자동 블록에는 내용 해시를 붙여 수동 블록과 구분한다. 자동 블록을 사람이 유효하게
수정하면 이후 수동 블록으로 취급한다. 본문 설명은 보존하고 생성 블록과 도구가 소유한
확인 안내만 갱신한다. 중복 블록·중복 키·닫히지 않은 블록은 파괴하지 않고 Actions
요약에 정리 필요를 안내한다. 코드 펜스 안의 예시는 자동 입력과 Merge 집계 모두 무시한다.

같은 PR은 concurrency로 직렬화하며, 본문이 같으면 PATCH하지 않는다. 쓰기 직전에
본문·HEAD·대상 브랜치 등을 다시 읽고 수정됐으면 재계산하며, ETag 조건도 전달한다.
GitHub API가 원자적 본문 비교·교체를 보장하는 것은 아니므로 확인과 PATCH 사이의
아주 짧은 동시 편집 경합은 완전히 제거할 수 없다. 최종 본문은 GitHub에서 검토한다.

워크플로는 `pull_request_target`에서 **기본 브랜치의 최신 신뢰된 코드만** checkout한다.
PR head checkout, 패키지 설치, PR 코드 실행, 캐시, PR artifact 실행은 하지 않는다.
권한은 `contents: read`, `issues: read`, `pull-requests: write`이며 별도 PAT나 외부 Secret을
사용하지 않는다. PR 텍스트는 JSON 데이터로만 취급하며 셸 코드에 삽입하지 않는다.
로그·Actions 요약에는 고정 안내만 기록한다.

본문 갱신은 Discord 알림·Pages 배포·Figma 동기화를 직접 호출하지 않는다. 기존 Discord는
`edited` 이벤트를 구독하지 않고 현황 집계는 `closed`만 구독하므로 알림을 중복 전송하지
않는다. `GITHUB_TOKEN`의 이벤트 재귀 제한에만 의존하지 않고 자체 멱등성도 유지한다.

### 설치 및 읽기 전용 검증

이 저장소는 기본 브랜치가 `main`이다. develop에만 파일을 넣은 상태는 배포 완료가 아니다.
사용자 승인 후 자동화 파일만 main에 반영하는 별도 PR에서 새 워크플로, `pr_metadata.py`,
공통 파서 `project_status.py` 및 두 레지스트리의 호환성을 함께 확인한다. 앱 기능 전체를
main으로 Merge할 필요는 없다. 승인 없이 main이나 Actions 설정을 변경하지 않는다.
워크플로만 먼저 반영되거나 기존 공통 파서가 남아 있어도 실패를 반복하지 않도록,
checkout 후 토큰을 메타데이터 스크립트에 전달하기 전에 자체 준비 검사를 수행한다.
별도 검사 스크립트가 없어도 동작하는 워크플로 내장 검사이며 다음을 확인한다.

- `pr_metadata.py`, `project_status.py`, 두 레지스트리 파일 존재 여부
- 모듈 import와 공통 파서 호환성
- JSON 로드 및 외부 API를 호출하지 않는 빈 입력 분류 검사

파일 누락·호환성 미충족·손상된 JSON이면 `ready=false`로 기록하고 본문 갱신 단계를
건너뛴다. 작업은 배포 대기 상태로 성공 종료하며 Actions 요약에 필요한 파일의 동시
배포를 안내한다. PR 본문은 수정하지 않고 Discord 등 외부 알림도 보내지 않는다.
파일이 정상적으로 갖춰지면 다음 이벤트 또는 수동 실행에서 자동으로 진행한다.
PR head나 develop의 스크립트로 대체 실행하지 않는다.

기본 브랜치에 워크플로 자체가 없으면 `pull_request_target` 자동 실행도 아직 등록되지
않은 상태다. 준비 검사는 워크플로가 배포되었지만 의존 파일이 준비되지 않은 공백을
보호하는 장치이며 main 배포를 대신하지 않는다.
저장소/조직의 Actions 이벤트 정책이 `pull_request_target`을 허용하는지도 관리자가 확인한다.
관련 정책은 [GitHub 보안 안내](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)를 참고한다.

설치 후 Actions → `PR 개발 현황 메타데이터` → Run workflow에서 PR 번호를 입력한다.
`apply`의 기본값은 false로, 읽기 전용 확인이다. true 선택은 실제 본문 갱신이므로
기존 PR #42·#38 검증에는 false만 사용한다. 별도 Discord Secret, Pages/Figma 활성화,
`PROJECT_STATUS_ENABLED` 설정은 필요 없다.

로컬에서는 다음처럼 기본 읽기 전용 CLI를 사용한다. 토큰은 채팅·코드에 적지 않고
환경에 안전하게 설정한 `GH_TOKEN`만 사용한다. `--apply`가 없으면 PATCH하지 않는다.

```bash
python .github/scripts/pr_metadata.py --repository tail-friends/tail-app --pr-number 42 --dry-run
python .github/scripts/pr_metadata.py --repository tail-friends/tail-app --pr-number 38 --dry-run
```

Codex 등의 PR 작성 도구도 동일 스크립트의 fixture 모드로 본문을 준비할 수 있다.
fixture는 `pull`(REST 형식의 title/body/base.ref/head.sha/draft/state), `files`(경로 배열),
`issues`(연결 Issue의 number/title/body 배열)를 포함한다. API 모델을 새로 정의하는 파일은 아니다.

```bash
python .github/scripts/pr_metadata.py --fixture .github/scripts/tests/fixtures/metadata-pr-42.json --output build/pr-metadata-42.json
python .github/scripts/pr_metadata.py --fixture .github/scripts/tests/fixtures/metadata-pr-38.json --output build/pr-metadata-38.json
python -m unittest discover -s .github/scripts/tests -p "test_*.py" -v
```

두 fixture는 실제 PR과 연결 Issue·파일 목록을 읽기 전용 조회한 스냅샷이다. 원본 수동
블록 보존과 블록을 제외한 자동 추론을 모두 테스트한다. 라이브 API PATCH와 실제 Actions
트리거 검증은 승인된 배포 이후에 별도로 수행해야 한다.

## Figma 버전 감지

Figma의 `FILE_VERSION_UPDATE`는 사용자가 파일 히스토리에 이름 붙인 버전을 만들 때
발생한다. 수신기는 passcode와 file key를 검증하고 GitHub `repository_dispatch`를
호출한다. Actions는 추적 대상 node 89개의 JSON을 버전별로 조회하고 안정적인 SHA-256
지문을 비교한다.

- 변경 node만 `review_required`로 표시한다.
- node를 판별할 수 없거나 Figma API가 실패하면 배포하지 않아 기존 완료 이력을 보존한다.
- API 연동 상태는 디자인 변경으로 되돌리지 않는다.
- 반영 PR에서 현재 `design_version`과 `design_review`를 명시하면 해당 node를 다시 승인한다.
- 동일 webhook/version은 Worker KV와 게시된 이전 상태 비교로 중복 처리하지 않는다.

### Webhook 없이 첫 동기화

1. Repository Settings → Secrets and variables → Actions에 `FIGMA_ACCESS_TOKEN`을 등록한다.
   `file_content:read`, `file_versions:read` scope만 부여한다.
2. Actions → `개발 현황 갱신` → Run workflow에서 `sync_figma`와
   `accept_figma_baseline`을 모두 선택한다.
3. 이후 수동 실행에서는 `sync_figma`만 선택한다. 정기 실행은 매일 05:17 KST다.

첫 실행에서 기준 승인 없이 조회만 하면 `baseline_required`로 표시하며 모든 화면을
변경됐다고 처리하지 않는다.

## GitHub Pages 관리자 설정

### 기본 브랜치 `main` 반영 절차

GitHub의 `schedule`, `workflow_dispatch`, `repository_dispatch`, `pull_request_target`는
워크플로 파일이 기본 브랜치에 있어야 안정적으로 등록된다. 이 저장소의 기본 브랜치는
`main`이므로 PR #33을 `develop`에 Merge하는 것만으로 자동화를 활성화할 수 없다.

안전한 활성화 순서는 다음과 같다.

아래 최초 설치 절차와 달리 이미 활성화된 저장소의 갱신에서는 기존 설정을 초기화하지
않는다. Issue #70 확인 시점에는 Pages가 Actions 방식으로 배포되고
`PROJECT_STATUS_ENABLED=true`였다. 이 값은 읽기만 했으며 변경하지 않았다.
갱신은 별도 승인된 자동화 릴리스와 dry_run 비교부터 진행한다.

1. PR #33을 검토해 `develop`에 Merge한다. 이 단계에서는
   `PROJECT_STATUS_ENABLED`를 설정하지 않아 기존 Discord Merge 알림을 유지한다.
2. 사용자 승인 후 최신 main에서 자동화 전용 릴리스 PR을 별도로 준비한다.
   develop 전체를 Merge하지 않는다. Issue #70의 `.github/scripts/project_status.py`,
   `.github/scripts/pr_metadata.py`, `.github/workflows/project-status.yml`, 템플릿,
   작업 규칙, 테스트/fixture, `project-status/site/`, 이 문서를 변경 목록으로 검토한다.
   main에 이미 존재하는 레지스트리·기존 Discord 스크립트·검증 CI·메타데이터 워크플로와
   호환성을 확인하고, 현재 main에 빠진 이전 pr_metadata 변경도 함께 검토한다.
   새 공유 helper를 사용하는 두 Python 파일은 같은 버전으로 반영해야 한다.
   Issue #70 확인 시점의 main에는 `pr_metadata.py`와 `project-status-metadata.yml`이
   없으며 검증 CI도 develop과 다르다. 이 선행 변경과 관련 테스트/fixture를 릴리스
   목록에 포함해 검토한다. main에 이미 있는 Discord/Worker 동작을 덮어쓰지 않는다.
3. 승인받은 릴리스 PR을 Merge한 뒤 Actions 목록에 `개발 현황 갱신`과
   `Project Status CI`가 등록됐는지 확인한다.
4. Pages Source를 GitHub Actions로 설정하고 첫 `workflow_dispatch`를 실행한다.
   Figma 기준 버전을 승인할 때만 `accept_figma_baseline`을 선택한다.
5. Pages 배포 URL과 Discord DRY_RUN 또는 테스트 채널 결과를 확인한 뒤에만
   `PROJECT_STATUS_ENABLED=true`를 설정한다.

`main`에 직접 Push하거나 사용자 승인 없이 릴리스 PR을 생성하지 않는다. 변경 목록에
Android/iOS 기능 파일이 포함되면 중단한다. 일부 파일만 먼저 배포해 서로 다른 버전의
helper를 import하게 하지 않는다. develop Merge만으로 main 워크플로의 입력/조건이나
Pages 배포가 완료됐다고 보고하지 않는다. 기존 현황 워크플로는 신뢰된 develop 코드를
checkout하므로 Python/정적 파일 변경은 다음 실행부터 사용될 수 있지만, PR 메타데이터
자동 입력은 기본 main 코드이므로 main 반영 전까지 새 항목을 읽지 못할 수 있다.

1. Repository Settings → Pages → Build and deployment의 Source를 `GitHub Actions`로 설정한다.
2. `github-pages` Environment에 필요한 승인 규칙이 있다면 팀 정책에 맞게 설정한다.
3. 최초 수동 배포가 성공하고 실제 URL을 확인한 뒤 Actions Variable
   `PROJECT_STATUS_ENABLED=true`를 등록한다.

이 Variable이 없으면 기존 Discord Merge 알림이 그대로 동작한다. 활성화 후에는 develop
Merge에서 현황 생성과 Pages 배포가 성공한 경우에만 진행률이 포함된 단일 알림을 보낸다.
각 성공 실행의 상태 JSON은 Actions artifact로 90일 보존하며 다음 실행에서 먼저 읽는다.
artifact가 없을 때만 기존 Pages 데이터를 조회한다.
예약·Figma dispatch·PR Merge 자동 실행은 `PROJECT_STATUS_ENABLED=true`일 때만 허용한다.
수동 실행은 초기 배포/읽기 전용 검증을 위해 별도로 허용한다. 이 작업에서 Variable,
Pages 설정, Worker 배포, Webhook 등록은 변경하지 않는다.
Pages 공개 범위는 저장소 공개 여부와 조직/플랜의 Pages 접근 정책에 따라 달라지므로
관리자가 실제 설정 화면에서 확인해야 한다. 코드에는 예상 URL을 넣지 않는다.

기본 브랜치 반영 후 확인 순서는 수동 dry_run → 데이터/필터/XLSX 비교 → 승인된 Pages
배포 → develop Merge 이벤트 → 승인된 Figma 버전/Webhook 이벤트다. Worker 코드나
status.json의 synced만으로 실제 FILE_VERSION_UPDATE 수신 성공을 단정하지 않는다.

필요한 GitHub 설정:

- Secret `DISCORD_WEBHOOK_URL`: 기존 값을 재사용한다.
- Secret `FIGMA_ACCESS_TOKEN`: Figma 파일·버전 읽기용이다.
- Variable `PROJECT_STATUS_ENABLED`: Pages 준비 후 `true`로 설정한다.

## 선택적 Figma Webhook 수신기

GitHub Actions는 Figma가 호출할 공개 HTTPS endpoint가 아니므로 외부 수신기가 필요하다.
`integrations/figma-webhook` 예시는 Cloudflare Worker 기준이며 저장소 배포와 분리된다.

1. `wrangler.toml.example`을 `wrangler.toml`로 복사하고 KV namespace ID를 설정한다.
2. `wrangler secret put FIGMA_WEBHOOK_PASSCODE`로 임의의 강한 passcode를 등록한다.
3. `wrangler secret put GITHUB_DISPATCH_TOKEN`으로 `tail-friends/tail-app` 한 저장소의
   Contents write 권한만 가진 fine-grained token을 등록한다.
4. Worker를 배포하고 실제 HTTPS URL을 확인한다.
5. Figma `POST /v2/webhooks`에 아래 값을 사용해 파일 webhook을 만든다.

```json
{
  "event_type": "FILE_VERSION_UPDATE",
  "context": "file",
  "context_id": "FpS23pMGjJtXRj0AYVMSDK",
  "endpoint": "실제로 배포된 Worker HTTPS URL",
  "passcode": "Worker Secret과 동일한 값",
  "description": "Tail Friends 디자인 버전 동기화"
}
```

Webhook 생성 토큰에는 Figma `webhooks:write` scope가 필요하다. Figma는 생성 직후 `PING`
이벤트를 보내므로 200 응답을 확인한다. Worker는 비밀값, payload 원문, GitHub token을
로그에 출력하지 않는다.

## API 명세 등록

OpenAPI/Swagger가 전달되기 전에는 API 작업을 추가하지 않는다. 전달 후 각 operation을
검토해 안정적인 `id`, `method`, `path`, 연동 대상 `figma_numbers`와 플랫폼별 상태를
`api-tasks.json`에 등록한다. 기존 작업 ID와 완료 이력은 삭제하거나 재사용하지 않는다.

아래는 구조 설명용 예시이며 현재 확정된 API 계약이 아니다.

```json
{
  "id": "API-PET-EXAMPLE",
  "method": "POST",
  "path": "/확정된-경로",
  "figma_numbers": ["03"],
  "integration": {
    "android": {
      "status": "not_started",
      "related_issues": [],
      "related_prs": [],
      "merge_date": null
    },
    "ios": {
      "status": "not_started",
      "related_issues": [],
      "related_prs": [],
      "merge_date": null
    }
  }
}
```
