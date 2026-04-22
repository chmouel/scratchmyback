---
skill: k8s-diagnose
description: Diagnose Kubernetes deployment failures by inspecting pods, events, nodes, and resources
---

# Kubernetes Deployment Diagnostic Skill

Systematically investigate why a Kubernetes deployment is failing to become available.

## What to do

When invoked, perform these diagnostic steps in order:

### 1. Identify the deployment and namespace
- Ask the user for deployment name if not provided
- Determine the namespace (default to `default` if not specified)

### 2. Check pod status
```bash
kubectl get pods -l <selector> -o wide
```
- Identify pods stuck in `Pending`, `ContainerCreating`, `ImagePullBackOff`, or `CrashLoopBackOff`
- Note pod names for detailed inspection

### 3. Get recent events
```bash
kubectl get events --sort-by='.lastTimestamp' -n <namespace>
```
- Filter for events related to the deployment/pods
- Look for keywords: `FailedScheduling`, `Insufficient`, `didn't match`, `unschedulable`, `node(s)`

### 4. Describe the deployment
```bash
kubectl describe deployment <name> -n <namespace>
```
- Check Conditions section
- Review Events at the bottom
- Note replica counts (desired vs available)

### 5. Describe failing pods
For each pod in bad state:
```bash
kubectl describe pod <pod-name> -n <namespace>
```
- Focus on the Events section
- Look for scheduling failures
- Check for resource constraints, node selector mismatches, or affinity violations

### 6. Check node resources and labels
```bash
kubectl get nodes --show-labels
kubectl describe nodes
```
- Compare pod requirements against node capabilities
- Check if node selectors match any nodes
- Verify sufficient allocatable resources (CPU, memory)

### 7. Inspect the deployment YAML
```bash
kubectl get deployment <name> -n <namespace> -o yaml
```
- Review nodeSelector, affinity, and tolerations
- Check resource requests/limits
- Verify image names and tags

## Root Cause Analysis

Common issues to detect:

1. **Node Selector Mismatch**
   - Pod requires labels like `disk-type: ssd` or `gpu: "true"` 
   - No nodes have these labels
   - Fix: Remove nodeSelector or add labels to nodes

2. **Excessive Resource Requests**
   - Pod requests more CPU/memory than any node has allocatable
   - Example: requests 512Gi memory or 128 CPUs
   - Fix: Reduce resource requests to realistic values

3. **Pod Anti-Affinity Conflicts**
   - Anti-affinity rules prevent pod from scheduling
   - Example: `requiredDuringSchedulingIgnoredDuringExecution` with single replica
   - Fix: Use `preferredDuringScheduling...` or remove for single replicas

4. **Taints and Tolerations**
   - Nodes have taints but pod lacks tolerations
   - Fix: Add tolerations or remove taints

5. **Image Pull Failures**
   - Image doesn't exist or requires authentication
   - Fix: Verify image name/tag, add imagePullSecrets if needed

## Output Format

Provide a concise report:

1. **Status**: Current state of deployment and pods
2. **Root Cause**: Specific issue identified from events/descriptions
3. **Evidence**: Relevant excerpt from kubectl output showing the problem
4. **Fix**: Exact YAML patch or kubectl command to resolve the issue

## Example invocation

User: "The nginx deployment isn't coming up"

You: Run diagnostics, find events showing "0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector", then report the node selector mismatch and suggest the fix.
