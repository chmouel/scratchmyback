#!/usr/bin/env bash
# Check if the current branch's PR touches .tekton/ files and send a Slack alert.
set -euo pipefail

# Only run from the PAC AI CI analysis context.
if [[ "${PAC_LLM_EXECUTION_CONTEXT:-}" != "ci" ]]; then
  echo "Not running in PAC CI analysis context — skipped."
  exit 0
fi

PLACEHOLDER="REPLACE_WITH_K8S_SECRET_SLACK_WEBHOOK_URL"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-${PLACEHOLDER}}"
PR_NUMBER="${PAC_PR_NUMBER:-0}"
PR_URL="${PAC_REPO_URL:-}"
if [[ -n "${PR_URL}" && "${PR_NUMBER}" != "0" ]]; then
  PR_URL="${PR_URL%/}/pull/${PR_NUMBER}"
fi

if [[ "${PR_NUMBER}" == "0" ]]; then
  echo "No pull request metadata available — skipped."
  exit 0
fi

CHANGED_FILES=""
if [[ -n "${PAC_CHANGED_FILES_B64:-}" ]]; then
  CHANGED_FILES=$(printf '%s' "${PAC_CHANGED_FILES_B64}" | base64 -d 2>/dev/null || true)
fi

if [[ -z "${CHANGED_FILES}" && -n "${PAC_REPO_OWNER:-}" && -n "${PAC_REPO_NAME:-}" ]] && command -v gh >/dev/null 2>&1; then
  CHANGED_FILES=$(gh api \
    "repos/${PAC_REPO_OWNER}/${PAC_REPO_NAME}/pulls/${PR_NUMBER}/files" \
    --paginate \
    --jq '.[].filename' 2>/dev/null || true)
fi

if [[ -z "${CHANGED_FILES}" ]]; then
  echo "No changed-file metadata available for PR #${PR_NUMBER} — skipped."
  exit 0
fi

TEKTON_FILES=$(printf '%s\n' "${CHANGED_FILES}" | sed '/^$/d' | grep '^\.tekton/' || true)

if [[ -z "$TEKTON_FILES" ]]; then
  echo "PR #${PR_NUMBER} has no .tekton/ changes — no notification sent."
  exit 0
fi

if [[ "$SLACK_WEBHOOK_URL" == "$PLACEHOLDER" ]]; then
  echo "SLACK_WEBHOOK_URL is not configured — skipped. Set it to the K8s secret value to enable notifications."
  exit 0
fi

FILE_COUNT=$(echo "$TEKTON_FILES" | wc -l | tr -d ' ')
BULLET_LIST=$(echo "$TEKTON_FILES" | sed 's/^/• /' | paste -sd $'\n' -)

PAYLOAD=$(jq -n \
  --arg pr_number "$PR_NUMBER" \
  --arg pr_title  "${PAC_PR_TITLE:-PR #${PR_NUMBER}}" \
  --arg pr_url    "$PR_URL" \
  --arg files     "$BULLET_LIST" \
  --arg count     "$FILE_COUNT" \
  '{
    blocks: [
      {
        type: "header",
        text: { type: "plain_text", text: "Tekton pipeline changes in PR" }
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: (if $pr_url != "" then "*PR #\($pr_number):* <\($pr_url)|\($pr_title)>" else "*PR #\($pr_number):* \($pr_title)" end)
        }
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: "*Changed .tekton/ files (\($count)):*\n\($files)"
        }
      }
    ]
  }')

curl -sf -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL"
echo "Slack notification sent for PR #${PR_NUMBER} (${FILE_COUNT} .tekton/ file(s) changed)."
