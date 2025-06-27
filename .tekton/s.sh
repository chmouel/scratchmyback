kubectl create secret generic gemini -n scratch-my-back --from-literal=secret="$(pass show google/gemini-api)"
kubectl create secret generic jira -n scratch-my-back --from-literal=secret="$(pass show jira/token)"
