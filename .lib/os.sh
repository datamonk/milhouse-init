#!/usr/bin/env bash

# @desc Check if script is run in terminal.
# @noargs
# @return 0  If script is run on terminal.
# @return 1 If script is not run on terminal.
function _is_terminal(){
    [[ -t 1 || -z ${TERM} ]] && return 0 || return 1
};

# @desc Check if internet connection (to google.com is available.
# @noargs
# @return 0  If script can connect to internet.
# @return 1 If script cannot access internet.
function check_internet_connection(){
    declare check_internet
    if _is_terminal; then
        check_internet="$(sh -ic 'exec 3>&1 2>/dev/null; { curl --compressed -Is google.com 1>&3; kill 0; } | { sleep 10; kill 0; }' || :)"
    else
        check_internet="$(curl --compressed -Is google.com -m 10)"
    fi
    if [[ -z ${check_internet} ]]; then
        return 1
    fi
};

# Return the available memory on the current OS in MB
function os_get_available_memory_mb(){
  free -m | awk 'NR==2{print $2}'
};

# Returns true (0) if this is an Ubuntu server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_ubuntu(){
  local -r version="$1"
  grep -q "Ubuntu $version" /etc/*release
};

# Returns true (0) if this is a CentOS/CentOS Stream server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_centos(){
  local -r version="$1"
  grep -q "CentOS Linux release $version" /etc/*release || grep -q "CentOS Stream release $version" /etc/*release
};

# Returns true (0) if this is a RedHat server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_redhat(){
  local -r version="$1"
  grep -q "Red Hat Enterprise Linux Server release $version" /etc/*release
};

# Validate that the given file has the given checksum of the given checksum type, where type is one of "md5" or
# "sha256".
function os_validate_checksum(){
  local -r filepath="$1"
  local -r checksum="$2"
  local -r checksum_type="$3"

  case "$checksum_type" in
    sha256)
      log_info "Validating sha256 checksum of $filepath is $checksum"
      echo "$checksum $filepath" | sha256sum -c
      ;;
    md5)
      log_info "Validating md5 checksum of $filepath is $checksum"
      echo "$checksum $filepath" | md5sum -c
      ;;
    *)
      log_error "Unsupported checksum type: $checksum_type."
      exit 1
  esac
};

# Returns true (0) if this the given command/app is installed and on the PATH or false (1) otherwise.
function os_command_is_installed(){
  local -r name="$1"
  command -v "$name" > /dev/null
};

# Get the username of the current OS user
function os_get_current_users_name(){
  id -u -n
};

# Get the name of the primary group for the current OS user
function os_get_current_users_group(){
  id -g -n
};

# Returns true (0) if the current user is root or sudo and false (1) otherwise.
function os_user_is_root_or_sudo(){
  [[ "$EUID" == 0 ]]
};

# Returns a zero exit code if the given $username exists
function os_user_exists(){
  local -r username="$1"
  id "$username" >/dev/null 2>&1
};

function sysctl_service_is_active(){
  # returns 0 if init.d service is in an 'active' state.
  sudo systemctl is-active --quiet $1
};

function is_docker_grp_member(){
  sudo getent group docker | grep $1
};
