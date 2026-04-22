#!/usr/bin/env bash
# Check if the current branch's PR touches .tekton/ files and send a Slack alert.
set -euo pipefail

# Only run inside a Kubernetes pod
if [[ -z "${KUBERNETES_SERVICE_HOST:-}" ]]; then
  echo "Not running in a Kubernetes pod — skipped."
  exit 0
fi

PLACEHOLDER="REPLACE_WITH_K8S_SECRET_SLACK_WEBHOOK_URL"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-${PLACEHOLDER}}"

# Resolve PR info for the current branch
PR_INFO=$(gh pr view --json number,title,url,files 2>/dev/null) || {
  echo "No open PR found for the current branch — skipped."
  exit 0
}

PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number')
PR_TITLE=$(echo "$PR_INFO"  | jq -r '.title')
PR_URL=$(echo "$PR_INFO"    | jq -r '.url')

# Filter for .tekton/ files
TEKTON_FILES=$(echo "$PR_INFO" | jq -r '.files[].path | select(startswith(".tekton/"))')

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
  --arg pr_title  "$PR_TITLE" \
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
          text: "*PR #\($pr_number):* <\($pr_url)|\($pr_title)>"
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
