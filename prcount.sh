#!/usr/bin/env bash
# Copyright 2024 Chmouel Boudjnah <chmouel@chmouel.com>
target=${1:-ghe-chmouel-gapps}
timestart=${2:-""}

TMP=$(mktemp /tmp/.mm.XXXXXX)
clean() { rm -f $TMP; }
trap clean EXIT

tkn pr ls --reverse --no-headers -n $target >$TMP

bgreen() { echo -e "\033[1;32m$*\033[0m"; }
bblue() { echo -e "\033[1;34m$*\033[0m"; }
byellow() { echo -e "\033[1;33m$*\033[0m"; }
bmagenta() { echo -e "\033[1;35m$*\033[0m"; }
bred() { echo -e "\033[1;31m$*\033[0m"; }

running=$(grep -wc 'Running$' $TMP)
pending=$(grep -wc PipelineRunPending $TMP)
success=$(grep -wc Succeeded $TMP)

if [[ -n $timestart ]]; then
	now=$(date +%s)
	finished=
	_elapsed=$((now - timestart))

	stillrunning=$(awk '{if ($NF == "Running") {c++} } END {print c}' $TMP)
	if [[ -z $stillrunning ]]; then
		if [[ -e /tmp/.pac-last-run-finished ]]; then
			finished=$(cat /tmp/.pac-last-run-finished)
			_elapsed=$((timestart - finished))
		else
			date '+%s' >/tmp/.pac-last-run-finished
		fi
	fi

	if [[ $_elapsed -gt 60 ]]; then
		_n=$((_elapsed / 60))mn
	else
		_n="${_elapsed}s"
	fi
	if [[ -n $finished ]]; then
		elapsed="Finished in $(bmagenta $_n)"
	else
		elapsed="Started $(bmagenta $_n) ago"
	fi
fi
[[ $running -gt 0 ]] && running=$(bblue $running)
[[ $pending -gt 0 ]] && pending=$(byellow $pending)
[[ $success -gt 0 ]] && success=$(bgreen $success)

sed -i 's/\bRunning$/'$(bblue Running)'/g' $TMP
sed -i 's/Running.PipelineRunPending./'$(byellow Pending)'/g' $TMP
sed -i 's/Succeeded/'$(bgreen Succeeded)'/g' $TMP

targetc=$(bred $target)
s="${targetc} - PR Running: $running Pending: $pending Success: $success $elapsed"
echo "$s"
nc=$(echo -n "$s" | sed 's/\x1B\[[0-9;]*[JKmsu]//g' | wc -c)
echo $(printf "%0.s-" $(seq 1 $nc))
cat $TMP
