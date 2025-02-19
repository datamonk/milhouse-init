#!/bin/bash
set -eu

__PROGNAME="${0##*/}";
__die(){ echo "${_PROGNAME}: error: $1" 1>&2; exit 1; };
__inet="$(sh -ic 'exec 3>&1 2>/dev/null; { curl --compressed -Is google.com 1>&3; kill 0; } | { sleep 10; kill 0; }' || :)";
[[ -z "$__inet" ]] && _die "can't reach internet. check conn and re-run.";
remote='https://raw.githubusercontent.com/datamonk/milhouse-init'; branch='main'; script='00-init.sh';
cd $HOME && curl -fsSL $remote/refs/heads/$branch/$script | bash
exit 0
