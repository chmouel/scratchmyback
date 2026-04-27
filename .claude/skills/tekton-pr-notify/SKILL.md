---
name: tekton-pr-notify
description: Always run this during CI-based PR review or pipeline failure investigation when a PR may touch .tekton/ files
version: 1.0.0
---

# Tekton PR Slack Notifier

Run this skill during CI-based pull request review or pipeline failure
investigation. It checks whether the pull request touches `.tekton/` files and,
if so, sends a Slack message to the configured webhook.

## When to use

- During AI review or AI investigation of a PipelineRun failure in CI
- Whenever you want to alert the team that a PR modifies Tekton pipeline definitions
- Only when `PAC_LLM_EXECUTION_CONTEXT=ci`

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

The script exits 0 in all non-fatal cases (no PR metadata, no `.tekton/`
changes, missing webhook). In PAC CI it uses `PAC_CHANGED_FILES_B64` as the
authoritative changed-file list instead of trying to infer the current PR from
the checked-out branch. Any output it prints is the status — relay it to the
user.

## Step 3: Report outcome

Tell the user one of:

- "No pull request metadata available — skipped."
- "PR #N has no `.tekton/` changes — no notification sent."
- "Slack notification sent for PR #N (N `.tekton/` files changed)."
- "SLACK_WEBHOOK_URL is not configured — skipped. Set it to the K8s secret value to enable notifications."

## Environment

`SLACK_WEBHOOK_URL` must be exported before running the script. This skill is
intended to send notifications only from PAC CI runs, and the script skips
execution unless `PAC_LLM_EXECUTION_CONTEXT=ci`. In PAC CI the following
metadata should be present:

- `PAC_PR_NUMBER`
- `PAC_PR_TITLE`
- `PAC_REPO_URL`
- `PAC_CHANGED_FILES_B64`

When using a Kubernetes secret, extract it with:

```bash
export SLACK_WEBHOOK_URL=$(kubectl get secret webhook -o jsonpath='{.data.webhook}' | base64 -d)
```

if it's not found then skip it sending the notification and report that the webhook is not configured.
