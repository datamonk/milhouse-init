#!/bin/bash
set -eu

usage(){
/bin/cat << EOF
A script for installing a docker-ce (Container service/runtime)
based on a set of defined params.

USAGE: ./install-docker.sh [OPTIONS] [-D]

OPTIONS:
  -h|--help     Show this message
  -c|--channel  [REQUIRED stable|test] Target channel for release install.
  -D|--dryrun   [OPTIONAL] Pass '--dryrun' flag to docker install.sh script.

Ex: ./install-docker.sh -c [-D]
EOF
};

if [ $# -eq 0 ]; then
  log_error "Required options(s) not provided."
  usage
  exit 1
fi
unset darg
while [ $# -gt 0 ]; do
  case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    -c | --channel)
      ch="$2"
      ;;
    -P | --prefix)
      SW_PREFIX="$2"
      ;;
    -D | --dryrun)
      darg="--dryrun"
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
  shift
done

function initParams(){
  wai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);
  source ${wai}/../.lib/src-libs.sh
  if [[ -z "${ch}" ]]; then
    log_error "####\n Required '-c' channel (stable|test) option not set\n####"
    usage && exit 1
  fi
  sname="docker" # shortname label used for dynamic logging reference.
  dlurl="https://get.docker.com" # Vendor docker script endpoint
  scrname="deploy-docker.sh" # Change the name from 'install-docker.sh' to avoid conflict.
};
function execDl(){
  curl --fail --silent --show-error --location \
       -XGET ${dlurl} \
       --output ${scrname} \
  && chmod 750 ${scrname}
  ret=$?
  if [ ! $ret -eq 0 ]; then
    log_error "${sname} download from [ ${dlurl} ] returned a non-zero response.\nCheck the curl call is valid." \
     && exit 1
  fi
};
function execInst(){
  log_info "Starting ${sname} install on $HOSTNAME"
  sh ${scrname} --channel ${ch} ${darg}
};
function torpedo(){
  initParams
  execDl
  execInst
};
torpedo
exit 0
