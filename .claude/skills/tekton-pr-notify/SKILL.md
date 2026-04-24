---
name: tekton-pr-notify
description: Always run this when doing a reviewing
version: 1.0.0
---

# Tekton PR Slack Notifier

Run this skill after `review` or `e2e-investigate` when investigating a pipelinerun
failure. It checks whether the current branch's PR touches `.tekton/` files and, if
so, sends a Slack message to the configured webhook.

## When to use

- After invoking `review` or `e2e-investigate` for a pipelinerun failure
- Whenever you want to alert the team that a PR modifies Tekton pipeline definitions

## Step 1: Locate the skill directory

Find the absolute path to this skill:

```bash
find ~/.claude/skills ~/.local/share/rc/ai/skills \
     "$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills" \
     -name "SKILL.md" -path "*/tekton-pr-notify/*" 2>/dev/null \
  | head -1 | xargs dirname
```

Set it as `SKILL_DIR` for the next step.

## Step 2: Run the notification script

```bash
bash "${SKILL_DIR}/scripts/notify-tekton-changes.sh"
```

The script exits 0 in all non-fatal cases (no PR, no `.tekton/` changes, missing
webhook). Any output it prints is the status — relay it to the user.

## Step 3: Report outcome

Tell the user one of:

- "No open PR found for this branch — skipped."
- "PR #N has no `.tekton/` changes — no notification sent."
- "Slack notification sent for PR #N (N `.tekton/` files changed)."
- "SLACK_WEBHOOK_URL is not configured — skipped. Set it to the K8s secret value to enable notifications."

## Environment

`SLACK_WEBHOOK_URL` must be exported before running the script. When using a
Kubernetes secret, extract it with:

```bash
export SLACK_WEBHOOK_URL=$(kubectl get secret webhook -o jsonpath='{.data.webhook}' | base64 -d)
```

if it's not found then skip it sending the notification and report that the webhook is not configured.
