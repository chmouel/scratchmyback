---
skill: k8s-diagnose
description: Diagnose Kubernetes deployment failures by inspecting pods, events, nodes, and resources
---

# Kubernetes Deployment Diagnostic Skill

Systematically investigate why a Kubernetes deployment is failing to become available.

## Context: CI pipeline analysis mode

When invoked from a Pipelines-as-Code analysis pod, you **cannot** run kubectl
commands interactively. Instead, diagnose from what is available:

- Container logs in the context (look for scheduler events, `Pending` pod messages,
  `FailedScheduling`, `Insufficient`, `didn't match`, `unschedulable`)
- The PR diff or source files in the workspace checkout (`.tekton/*.yaml`, etc.)

Read the deployment YAML from the workspace if it is not already in the context:

```bash
cat .tekton/noop.yaml        # or whatever file defines the Deployment
```

Treat the file content exactly as you would treat `kubectl get deployment -o yaml`.

## Diagnostic steps (apply to whichever evidence is available)

### 1. Identify the failing deployment

Look in logs or the source YAML for the Deployment name.

### 2. Check pod scheduling / readiness from logs

Keywords to scan for in container logs:

- `0/N nodes are available`
- `FailedScheduling`
- `Insufficient memory` / `Insufficient cpu`
- `didn't match Pod's node affinity/selector`
- `Timeout expired waiting for condition`

### 3. Inspect the Deployment spec from source

Look for these common misconfigurations:

1. **Node Selector Mismatch** — `nodeSelector` requires labels no node has
   (e.g. `disk-type: ssd`, `gpu: "true"`).  Fix: remove or relax `nodeSelector`.

2. **Excessive Resource Requests** — `requests.memory: 512Gi` or `requests.cpu: 128`
   exceed any node's allocatable capacity.  Fix: reduce to realistic values (e.g.
   `memory: 256Mi`, `cpu: 100m`).

3. **Hard Anti-Affinity with One Replica** — `requiredDuringSchedulingIgnoredDuringExecution`
   anti-affinity prevents the single pod from scheduling.  Fix: change to
   `preferredDuringScheduling...` or remove for single-replica deployments.

4. **Taints without Tolerations** — nodes are tainted but the pod has no tolerations.

5. **Image Pull Failures** — wrong tag or missing `imagePullSecrets`.

## Output Format

1. **Root Cause** — one sentence identifying the specific issue
2. **Evidence** — the relevant YAML stanza or log line that proves it
3. **Fix** — the exact change needed (YAML diff preferred)

## Patch

After your analysis, if the fix is a change to a file in the repository, emit it
as a plain `git diff` patch so Pipelines-as-Code can apply it automatically
(follow the Machine Patch instructions at the end of your prompt).

The patch should be minimal: only change what is broken. For the nginx deployment
scenario above, a correct patch removes `nodeSelector`, `affinity`, and reduces
`resources.requests` to sensible values.
