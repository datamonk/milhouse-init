#!/usr/bin/env bash

# \section Introduction
# The Bash Shell Function Library (BSFL) is a small Bash script that acts as a library
# for bash scripts. It provides a couple of functions that makes the lives of most
# people using shell scripts a bit easier.

# Based on The Bash Shell Function Library (BSFL) project:
#   https://github.com/SkypLabs/bsfl (@author Louwrentius <louwrentius@gmail.com>)

#############

# create a new dir and enter it
function mkd(){
  mkdir -p "$@" && cd "$_";
};

# Group: File and Directory
# ----------------------------------------------------#

# @fn directory_exists()
# @ingroup file_and_dir
# @brief Tests if a directory exists.
# @param directory Directory to operate on.
# @retval 0 if the directory exists.
# @retval 1 in others cases.
function directory_exists(){
    if [[ -d "$1" ]]; then
        return 0
    fi
    return 1
};

# @fn file_exists()
# @ingroup file_and_dir
# @brief Tests if a file exists.
# @param file File to operate on.
# @retval 0 if the (regular) file exists.
# @retval 1 in others cases.
function file_exists(){
    if [[ -f "$1" ]]; then
        return 0
    fi
    return 1
};

# @fn device_exists()
# @ingroup file_and_dir
# @brief Tests if a device exists.
# @param device Device file to operate on.
# @retval 0 if the device exists.
# @retval 1 in others cases.
function device_exists(){
    if [[ -b "$1" ]]; then
        return 0
    fi
    return 1
};

# Group: String
# ----------------------------------------------------#

# @fn to_lower()
# @ingroup string
# @brief Converts uppercase characters in a string to lowercase.
# @param string String to operate on.
# @return Lowercase string.
function to_lower(){
    echo "$1" | tr '[:upper:]' '[:lower:]'
};

# @fn to_upper()
# @ingroup string
# @brief Converts lowercase characters in a string to uppercase.
# @param string String to operate on.
# @return Uppercase string.
function to_upper(){
    echo "$1" | tr '[:lower:]' '[:upper:]'
};

# @fn trim()
# @ingroup string
# @brief Removes whitespace from both ends of a string.
# @see <a href="https://unix.stackexchange.com/a/102021">Linux Stack Exchange</a>
# @param string String to operate on.
# @return The string stripped of whitespace from both ends.
function trim(){
    echo "${1}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
};

# @fn is_ipv4_addr()
# @desc Performs basic regex check for validity of IPv4 address format for the
#       provided string.
# @param String to validate (ie, XX.XX.XX.XX)
# @retval 0 if valid IPv4 format.
# @retval 1 if failed to match IPv4 regex filter.
function is_ipv4_addr(){
  ipv4_filter='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';
  local -r ipv4_entry="$1";
  if echo $ipv4_entry | grep -Eq ${ipv4_filter}; then
    #log_info "Valid IP: ${entry}"
    return 0
  else
    return 1
  fi
};

# Group: Time
# ----------------------------------------------------#

# @fn now()
# @ingroup time
# @brief Displays the current timestamp.
# @return Current timestamp.
function now(){
    date +%s
};

# @fn epoch() **DUPLICATE**
# @brief Displays the current timestamp in EPOCH format.
# @return Current timestamp in EPOCH.
# note this is a dup function from `now` because im not sure what it will
# break in the short-term by renaming. Will need to re-visit and cleanup.
function epoch_time(){
    date +%s
};

# @fn elapsed()
# @ingroup time
# @brief Displays the time elapsed between the 'start' and 'stop'
# parameters.
# @param start Start timestamp.
# @param stop Stop timestamp.
# @return Time elapsed between the 'start' and 'stop' parameters.
function elapsed(){
    START="$1"
    STOP="$2"

    ELAPSED=$(( STOP - START ))
    echo $ELAPSED
};

# @fn start_watch()
# @ingroup time
# @brief Starts the watch.
function start_watch(){
    __START_WATCH=$(now)
};

# @fn stop_watch()
# @ingroup time
# @brief Stops the watch and displays the time elapsed.
# @retval 0 if succeed.
# @retval 1 if the watch has not been started.
# @return Time elapsed since the watch has been started.
function stop_watch(){
    if has_value __START_WATCH; then
        STOP_WATCH=$(now)
        elapsed "$__START_WATCH" "$STOP_WATCH"
        return 0
    else
        return 1
    fi
};
