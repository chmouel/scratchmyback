---
name: "failure-analysis"
output: "check-run"
context_items:
  error_content: true
  diff_content: true
  container_logs:
    enabled: true
    max_lines: 100
---
Analyze why this CI pipeline failed. Examine the container logs, exit codes, and
code diff to identify the root cause. If the failure is caused by a code bug,
explain the issue clearly and provide a concrete fix as a diff snippet. Keep the
response concise and actionable.
