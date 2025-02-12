#!/usr/bin/env bash

# Set colors
bold=""
reset="\e[0m"
green="\e[1;32m"
orange="\e[1;33m"
purple="\e[1;35m"
red="\e[1;31m"
white="\e[1;37m"
yellow="\e[1;33m"

# Echo to stderr. Useful for printing script usage information.
function echo_stderr(){
  >&2 echo "$@"
};

# Log the given message at the given level. All logs are written to stderr with a timestamp.
function log(){
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local -r script_name="$(basename "$0")"
  echo_stderr -e "${timestamp} [${level}] [$script_name] ${message}"
};

# Log the given message at INFO level. All logs are written to stderr with a timestamp.
# ex, log_info "hello world."
function log_info(){
  local -r message="$1"
  log "${bold}${green}INFO${reset}" "$message"
};

# Log the given message at WARN level. All logs are written to stderr with a timestamp.
function log_warn(){
  local -r message="$1"
  log "${bold}${yellow}WARN${reset}" "$message"
};

# Log the given message at ERROR level. All logs are written to stderr with a timestamp.
function log_error(){
  local -r message="$1"
  log "${bold}${red}ERROR${reset}" "$message"
};
