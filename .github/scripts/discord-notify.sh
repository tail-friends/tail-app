#!/usr/bin/env bash
# Tail Friends 앱 저장소의 GitHub 이벤트를 Discord 웹훅으로 알린다.
#
# 사용법: discord-notify.sh <pr-opened | review-requested | pr-merged | review | project-status>
#
# 공통 환경 변수
#   DISCORD_WEBHOOK_URL  Discord 채널 웹훅 주소 (Actions Secret)
#   DISCORD_USER_MAP     GitHub 아이디 → Discord 사용자 ID JSON (Actions Variable)
#                        예: {"github-login":"123456789012345678"}
#   DISCORD_APP_MENTIONS 리뷰어가 없거나 매핑되지 않았을 때 알릴 앱 팀원 멘션
#                        (Actions Variable). 예: <@123456789012345678> <@234567890123456789>
#   DRY_RUN=1            웹훅을 호출하지 않고 생성한 JSON만 출력한다.
#
# PR 환경 변수
#   PR_TITLE, PR_URL, PR_NUMBER, PR_AUTHOR, PR_BASE, PR_BODY
#   PR_REVIEWERS(공백으로 구분한 GitHub 아이디), PR_MERGED_BY
#
# 리뷰 환경 변수
#   REVIEW_STATE, REVIEW_AUTHOR, REVIEW_BODY, REVIEW_URL
set -euo pipefail

kind=${1:?'알림 종류가 필요합니다: pr-opened | review-requested | pr-merged | review | project-status'}

webhook_url=$(printf '%s' "${DISCORD_WEBHOOK_URL:-}" | tr -d '[:space:]')
if [[ "${DRY_RUN:-}" != "1" ]]; then
  if [[ -z "$webhook_url" ]]; then
    echo "DISCORD_WEBHOOK_URL 시크릿이 없어 Discord 알림을 건너뜁니다."
    exit 0
  fi
  if [[ "$webhook_url" != https://discord.com/api/webhooks/* ]]; then
    echo "::error::DISCORD_WEBHOOK_URL이 올바른 Discord 웹훅 주소 형식이 아닙니다."
    exit 1
  fi
fi

raw_user_map=${DISCORD_USER_MAP:-}
if [[ -z "$raw_user_map" ]] || ! printf '%s' "$raw_user_map" | jq -e 'type == "object"' >/dev/null 2>&1; then
  user_map='{}'
else
  user_map=$(printf '%s' "$raw_user_map" | jq -c '
    with_entries(select(.value | type == "string" and test("^[0-9]{17,20}$")))
  ')
fi

mapped_user_id() {
  printf '%s' "$user_map" | jq -r --arg login "$1" '.[$login] // empty'
}

mention_if_mapped() {
  local id
  id=$(mapped_user_id "$1")
  if [[ -n "$id" ]]; then
    printf '<@%s>' "$id"
  fi
}

configured_app_mentions() {
  printf '%s' "${DISCORD_APP_MENTIONS:-}" \
    | grep -oE '<@!?[0-9]{17,20}>' \
    | sed -E 's/^<@!?([0-9]+)>$/<@\1>/' \
    | awk '!seen[$0]++' \
    | paste -sd ' ' - || true
}

default_review_mentions() {
  local author_id token result=''
  author_id=$(mapped_user_id "${PR_AUTHOR:-}")
  for token in $(configured_app_mentions); do
    if [[ -n "$author_id" && "$token" == "<@$author_id>" ]]; then
      continue
    fi
    result+="${result:+ }$token"
  done
  printf '%s' "$result"
}

requested_reviewer_mentions() {
  local login mention result=''
  for login in ${PR_REVIEWERS:-}; do
    if [[ "$login" == "${PR_AUTHOR:-}" ]]; then
      continue
    fi
    mention=$(mention_if_mapped "$login")
    if [[ -n "$mention" && " $result " != *" $mention "* ]]; then
      result+="${result:+ }$mention"
    fi
  done
  if [[ -z "$result" ]]; then
    result=$(default_review_mentions)
  fi
  printf '%s' "$result"
}

send_payload() {
  local payload=$1
  if [[ "${DRY_RUN:-}" == "1" ]]; then
    printf '%s\n' "$payload"
    return
  fi
  curl --fail --silent --show-error \
    --header 'Content-Type: application/json' \
    --data "$payload" \
    "$webhook_url"
  echo "Discord 알림을 보냈습니다. ($kind)"
}

message() {
  local content=$1 title=$2 url=$3 description=$4 color=$5 fields=$6
  local ids allowed_users
  ids=$(printf '%s\n' "$content" \
    | grep -oE '<@!?[0-9]{17,20}>' \
    | grep -oE '[0-9]+' \
    | sort -u || true)
  allowed_users=$(printf '%s\n' "$ids" | jq -Rsc 'split("\n") | map(select(length > 0))')

  jq -n \
    --arg content "$content" \
    --arg title "$title" \
    --arg url "$url" \
    --arg description "${description:0:3500}" \
    --argjson color "$color" \
    --argjson fields "$fields" \
    --argjson allowed_users "$allowed_users" \
    '{
      content: $content,
      allowed_mentions: { parse: [], users: $allowed_users },
      embeds: [{
        title: $title,
        url: $url,
        description: $description,
        color: $color,
        fields: $fields
      }]
    }'
}

field() {
  jq -n --arg name "$1" --arg value "$2" '{ name: $name, value: $value, inline: true }'
}

clean_pr_body() {
  printf '%s\n' "${PR_BODY:-}" \
    | tr -d '\r' \
    | sed '/<!--[[:space:][:print:]]*-->/d' \
    | grep -viE '^[[:space:]]*(closes|fixes|resolves)[[:space:]]+#[0-9]+' || true
}

preferred_pr_section() {
  clean_pr_body | awk '
    function heading_text(line, value) {
      value = line
      sub(/^[[:space:]]*#+[[:space:]]*/, "", value)
      sub(/[[:space:]]*#+[[:space:]]*$/, "", value)
      return tolower(value)
    }
    /^[[:space:]]*#+[[:space:]]+/ {
      heading = heading_text($0)
      if (found) exit
      if (heading == "개요" || heading == "요약" || heading == "작업 목적" ||
          heading == "summary" || heading == "overview") {
        found = 1
        next
      }
    }
    found { print }
  '
}

pr_summary() {
  local summary
  summary=$(preferred_pr_section | sed '/^[[:space:]]*$/d' | head -n 12)
  if [[ -z "$summary" ]]; then
    summary=$(clean_pr_body \
      | sed -E '/^[[:space:]]*#+[[:space:]]+/d; /^[[:space:]]*$/d' \
      | head -n 12)
  fi
  printf '%s' "${summary:-PR 본문에 요약할 내용이 없습니다.}"
}

common_fields() {
  jq -n \
    --argjson author "$(field '작성자' "${PR_AUTHOR:-알 수 없음}")" \
    --argjson base "$(field '대상 브랜치' "${PR_BASE:-알 수 없음}")" \
    '[$author, $base]'
}

pr_opened() {
  local mentions content
  mentions=$(requested_reviewer_mentions)
  content="${mentions:+$mentions }📱 Tail Friends 앱 PR 리뷰 요청"

  send_payload "$(message \
    "$content" \
    "#${PR_NUMBER} ${PR_TITLE}" \
    "$PR_URL" \
    "$(pr_summary)" \
    5814783 \
    "$(common_fields)")"
}

review_requested() {
  local mentions reviewers_label
  mentions=$(requested_reviewer_mentions)
  reviewers_label=${PR_REVIEWERS:-앱 팀}

  send_payload "$(message \
    "${mentions:+$mentions }📱 Tail Friends 앱 PR 리뷰어가 지정됐어요." \
    "#${PR_NUMBER} ${PR_TITLE}" \
    "$PR_URL" \
    "$(pr_summary)" \
    5814783 \
    "$(jq -n \
      --argjson author "$(field '작성자' "${PR_AUTHOR:-알 수 없음}")" \
      --argjson base "$(field '대상 브랜치' "${PR_BASE:-알 수 없음}")" \
      --argjson reviewers "$(field '요청된 리뷰어' "$reviewers_label")" \
      '[$author, $base, $reviewers]')")"
}

pr_merged() {
  send_payload "$(message \
    "🎉 Tail Friends 앱 PR #${PR_NUMBER}이 ${PR_BASE}에 Merge됐어요." \
    "#${PR_NUMBER} ${PR_TITLE}" \
    "$PR_URL" \
    "$(pr_summary)" \
    10181046 \
    "$(jq -n \
      --argjson author "$(field '작성자' "${PR_AUTHOR:-알 수 없음}")" \
      --argjson merged_by "$(field 'Merge한 사람' "${PR_MERGED_BY:-알 수 없음}")" \
      --argjson base "$(field '대상 브랜치' "${PR_BASE:-알 수 없음}")" \
      '[$author, $merged_by, $base]')")"
}

review() {
  local state headline color author_notice review_body
  state=$(printf '%s' "${REVIEW_STATE:-}" | tr '[:upper:]' '[:lower:]')
  case "$state" in
    approved)
      headline='✅ Approve 리뷰가 등록됐어요.'
      color=5763719
      ;;
    changes_requested)
      headline='🔁 Changes requested 리뷰가 등록됐어요.'
      color=15548997
      ;;
    *)
      echo "리뷰 상태가 ${REVIEW_STATE:-없음}이므로 Discord 알림을 건너뜁니다."
      return
      ;;
  esac

  author_notice=$(mention_if_mapped "${PR_AUTHOR:-}")
  if [[ -z "$author_notice" ]]; then
    author_notice="GitHub @${PR_AUTHOR:-알 수 없음}"
  fi
  review_body=$(printf '%s' "${REVIEW_BODY:-}" | tr -d '\r')
  if [[ -z "${review_body//[[:space:]]/}" ]]; then
    review_body='(리뷰 코멘트 없음)'
  fi

  send_payload "$(message \
    "$author_notice $headline" \
    "#${PR_NUMBER} ${PR_TITLE}" \
    "${REVIEW_URL:-$PR_URL}" \
    "${review_body:0:1000}" \
    "$color" \
    "$(jq -n \
      --argjson author "$(field '작성자' "${PR_AUTHOR:-알 수 없음}")" \
      --argjson reviewer "$(field '리뷰어' "${REVIEW_AUTHOR:-알 수 없음}")" \
      --argjson base "$(field '대상 브랜치' "${PR_BASE:-알 수 없음}")" \
      '[$author, $reviewer, $base]')")"
}

project_status() {
  local notification status page_url event_kind title url description color fields
  notification=${STATUS_NOTIFICATION_JSON:-}
  status=${STATUS_DATA_JSON:-}
  page_url=${STATUS_PAGE_URL:-}

  if [[ -n "${STATUS_NOTIFICATION_PATH:-}" && -f "$STATUS_NOTIFICATION_PATH" ]]; then
    notification=$(<"$STATUS_NOTIFICATION_PATH")
  fi
  if [[ -n "${STATUS_DATA_PATH:-}" && -f "$STATUS_DATA_PATH" ]]; then
    status=$(<"$STATUS_DATA_PATH")
  fi

  if ! printf '%s' "$notification" | jq -e 'type == "object"' >/dev/null 2>&1 || \
    ! printf '%s' "$status" | jq -e 'type == "object"' >/dev/null 2>&1; then
    echo "::error::개발 현황 알림 JSON 형식이 올바르지 않습니다."
    exit 1
  fi
  if [[ "$page_url" != https://* ]]; then
    echo "::error::실제 GitHub Pages 배포 URL을 확인할 수 없습니다."
    exit 1
  fi

  event_kind=$(printf '%s' "$notification" | jq -r '.kind')
  case "$event_kind" in
    merge)
      title=$(printf '%s' "$notification" | jq -r '"#\(.pr_number) \(.title)"')
      url=$(printf '%s' "$notification" | jq -r '.url')
      description=$(printf '%s' "$notification" | jq -r '
        "완료 범위: " + (.scope // "확인 필요") +
        if (.figma_numbers | length) > 0 then "\nFigma: " + (.figma_numbers | join(", ")) else "" end +
        if (.api_work_ids | length) > 0 then "\nAPI: " + (.api_work_ids | join(", ")) else "" end
      ')
      color=10181046
      ;;
    figma-change)
      title=$(printf '%s' "$notification" | jq -r '
        "Figma 버전 변경 · " + (.version.label // .version.id)
      ')
      url=$(printf '%s' "$notification" | jq -r '.figma_url')
      description=$(printf '%s' "$notification" | jq -r '
        "재검토 필요:\n" + (.details | join("\n"))
      ')
      color=15844367
      ;;
    metadata-review)
      title=$(printf '%s' "$notification" | jq -r '"#\(.pr_number) 현황 메타데이터 확인 필요"')
      url=$(printf '%s' "$notification" | jq -r '.url')
      description=$(printf '%s' "$notification" | jq -r '.reasons | join("\n")')
      color=15548997
      ;;
    none)
      echo "개발 현황 변경이 없어 Discord 알림을 건너뜁니다."
      return
      ;;
    *)
      echo "::error::알 수 없는 개발 현황 이벤트: $event_kind"
      exit 1
      ;;
  esac

  progress_field() {
    local kind=$1 platform=$2 label=$3 value
    value=$(printf '%s' "$status" | jq -r --arg kind "$kind" --arg platform "$platform" '
      .progress[$kind][$platform] |
      if .state == "ready" then
        "\(.percent)% 완료 · \(.remaining_percent)% 남음"
      else
        "집계 준비 중"
      end
    ')
    field "$label" "$value"
  }

  fields=$(jq -n \
    --argjson android_ui "$(progress_field ui android 'Android UI')" \
    --argjson ios_ui "$(progress_field ui ios 'iOS UI')" \
    --argjson android_api "$(progress_field api android 'Android API')" \
    --argjson ios_api "$(progress_field api ios 'iOS API')" \
    --argjson dashboard "$(field '전체 현황표' "[GitHub Pages에서 열기]($page_url)")" \
    '[$android_ui, $ios_ui, $android_api, $ios_api, $dashboard]')

  send_payload "$(message \
    "📊 Tail Friends 개발 현황이 갱신됐어요." \
    "$title" \
    "$url" \
    "$description" \
    "$color" \
    "$fields")"
}

case "$kind" in
  pr-opened) pr_opened ;;
  review-requested) review_requested ;;
  pr-merged) pr_merged ;;
  review) review ;;
  project-status) project_status ;;
  *)
    echo "::error::알 수 없는 알림 종류: $kind"
    exit 1
    ;;
esac
