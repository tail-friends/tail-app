#!/usr/bin/env bash
# Tail Friends 앱 저장소의 GitHub 이벤트를 Discord 웹훅으로 알린다.
#
# 사용법: discord-notify.sh <pr-opened | review-requested | pr-merged | review>
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

kind=${1:?'알림 종류가 필요합니다: pr-opened | review-requested | pr-merged | review'}

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

case "$kind" in
  pr-opened) pr_opened ;;
  review-requested) review_requested ;;
  pr-merged) pr_merged ;;
  review) review ;;
  *)
    echo "::error::알 수 없는 알림 종류: $kind"
    exit 1
    ;;
esac
