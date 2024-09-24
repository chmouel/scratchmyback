#!/usr/bin/env bash
# Copyright 2024 Chmouel Boudjnah <chmouel@chmouel.com>
set -eufo pipefail

refreshsecond=${1:-2}
[[ -e /tmp/.pac-last-run-started ]] && start=$(cat /tmp/.pac-last-run-started) || start=$(date +%s)
watch -n${refreshsecond} -c bash ./prcount.sh scratch-my-back $start
