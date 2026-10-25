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

API 진행률의 분모는 `api-tasks.json`에 명세 근거와 함께 등록된 작업만 사용한다.
목록이 비어 있는 현재는 `0%`가 아니라 `집계 준비 중`으로 표시한다. Backend 구현과
Android/iOS 연동 상태는 `integration.android`, `integration.ios`로 분리한다.

초기 Android 완료 이력은 실제 develop Merge로 확인된 PR #20(01 로그인),
PR #24(02 홈), PR #22(03 개체 등록), PR #29(03-4 종 선택)이다. PR #29의 Merge
커밋은 `5a894d7`이며 Issue #28과 Merge 시각을 03-4 레지스트리에 기록한다.

## PR 메타데이터

PR 템플릿의 `tail-status` 주석 블록을 사용한다.

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
- `completed`: `true`일 때만 완료로 집계한다.
- `api_work_ids`: API 작업일 때 등록된 ID를 적는다.
- `design_version`: 디자인 변경 검토를 끝낸 Figma version ID다.
- `design_review`: `implemented` 또는 `no_changes_needed`만 허용한다.

`develop`에 실제 Merge된 PR만 읽는다. 번호가 없거나 레지스트리에 없는 번호가 있으면
해당 PR 전체를 완료 처리하지 않고 확인 목록에 남긴다. `main` 릴리스 PR은 조회 대상이
아니므로 중복 집계되지 않는다. PR 제목은 판정에 사용하지 않는다.

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

1. PR #33을 검토해 `develop`에 Merge한다. 이 단계에서는
   `PROJECT_STATUS_ENABLED`를 설정하지 않아 기존 Discord Merge 알림을 유지한다.
2. 팀의 정식 릴리스 절차로 `develop` → `main` PR을 생성한다. PR에서
   `.github/workflows/project-status.yml`, 검증 CI, 신뢰된 스크립트와 정적 현황표가
   함께 반영되는지 확인하고, 다른 미승인 변경이 섞였다면 Merge하지 않는다.
3. 승인받은 릴리스 PR을 Merge한 뒤 Actions 목록에 `개발 현황 갱신`과
   `Project Status CI`가 등록됐는지 확인한다.
4. Pages Source를 GitHub Actions로 설정하고 첫 `workflow_dispatch`를 실행한다.
   Figma 기준 버전을 승인할 때만 `accept_figma_baseline`을 선택한다.
5. Pages 배포 URL과 Discord DRY_RUN 또는 테스트 채널 결과를 확인한 뒤에만
   `PROJECT_STATUS_ENABLED=true`를 설정한다.

`main`에 직접 Push하거나 PR #33에서 `main`을 수정하지 않는다. `develop` → `main`
전체 릴리스가 아직 준비되지 않았다면 자동화 활성화를 보류하고 기존 Discord 알림을
계속 사용한다. 일부 파일만 임의로 복사하면 워크플로와 스크립트 버전이 어긋날 수 있으므로
별도 승인된 hotfix 절차가 없는 한 사용하지 않는다.

1. Repository Settings → Pages → Build and deployment의 Source를 `GitHub Actions`로 설정한다.
2. `github-pages` Environment에 필요한 승인 규칙이 있다면 팀 정책에 맞게 설정한다.
3. 최초 수동 배포가 성공하고 실제 URL을 확인한 뒤 Actions Variable
   `PROJECT_STATUS_ENABLED=true`를 등록한다.

이 Variable이 없으면 기존 Discord Merge 알림이 그대로 동작한다. 활성화 후에는 develop
Merge에서 현황 생성과 Pages 배포가 성공한 경우에만 진행률이 포함된 단일 알림을 보낸다.
각 성공 실행의 상태 JSON은 Actions artifact로 90일 보존하며 다음 실행에서 먼저 읽는다.
artifact가 없을 때만 기존 Pages 데이터를 조회한다.
Pages 공개 범위는 저장소 공개 여부와 조직/플랜의 Pages 접근 정책에 따라 달라지므로
관리자가 실제 설정 화면에서 확인해야 한다. 코드에는 예상 URL을 넣지 않는다.

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
