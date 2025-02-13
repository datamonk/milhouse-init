#!/bin/bash
set -eu

__PROGNAME="${0##*/}"
__die(){ echo "${__PROGNAME}: error: $1" 1>&2; exit 1; };
__isnotempty(){ [ "$1" ] && return 0 || return 1; };
__validate_input(){
   [ "$2" ] || __die "$1 requires an argument str"
#  example usage:
#    __validate_input "${FUNCNAME[0]}" "$1"
#    __isnotempty "$(container_id "$1")"
};
mkd(){ mkdir -p "$@" && cd "$_"; };
wai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);

## logger ##
bold=""
reset="\e[0m"
green="\e[1;32m"
orange="\e[1;33m"
purple="\e[1;35m"
red="\e[1;31m"
white="\e[1;37m"
yellow="\e[1;33m"
function echo_stderr(){ >&2 echo "$@"; };
function log(){
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local -r script_name="$(basename "$0")"
  echo_stderr -e "${timestamp} [${level}] [$script_name] ${message}"
};
function log_info(){
  local -r message="$1"
  log "${bold}${green}INFO${reset}" "$message"
};
function log_warn(){
  local -r message="$1"
  log "${bold}${yellow}WARN${reset}" "$message"
};
function log_error(){
  local -r message="$1"
  log "${bold}${red}ERROR${reset}" "$message"
};
####

function mntUSB(){
  local -r usbdev='/dev/sda1';
  if [[ -b "$usbdev" ]]; then
    usbmnt=$(mount | grep "$usbdev" | cut -d' ' -f3)
    if [[ $(__isnotempty $usbmnt) -eq 0 ]]; then
      log_info "existing $usbdev mnt found at [ $usbmnt ]"
    else
      usbmnt="/media/$USER/ORBITKEY"; # failback to static def
      log_warn "$usbdev mnt point returned null. attempting to mnt at [ $usbmnt ]"
      sudo mount $usbdev $usbmnt -o uid=$USER,gid=$USER \
      && log_info "USB media mounted at: [$(mount | grep $usbmnt)]"
    fi
    bsdir="$usbmnt/hc/bootstrap";
  else
    log_error "usb dev path not found."
    __die "${FUNCNAME[0]}: unable to mnt usb for secrets def. bailing."
  fi
};
function mkDirs(){
  cd $HOME
  mkdir -p "$HOME/proj/software" \
           "$HOME/data" \
           "$HOME/certs" \
           "$HOME/scripts" \
           "$HOME/tmp" \
           "$HOME/.secrets"
  ln -s proj/github gh \
  && ln -s proj/software sw \
  && ln -s .secrets .creds
};
function confGit(){
  local -r gitemail="acamara86@gmail.com";
  local -r gitcreds="$bsdir/.git-token";
  local -r bsrepo="https://$(cat $gitcreds)@github.com/datamonk/hamster-cannon.git";
  if [[ -f "$gitcreds" ]]; then
    log_info "Applying global setting for git env."
    git config --global user.email "$gitemail" \
    && git config --global user.name "$USER" \
    && git config --global credential.helper "store --file $HOME/.git-credentials"
    mkd "$HOME/proj/github" \
    && git clone "$bsrepo"
    if [[ ! -f ./"README.md" ]]; then
      log_error "hamster-cannon repo clone failed."
    fi
  fi
};
function confSsh(){
  local -r newkeypair="true"; # false to cp from usb
  mkd "$HOME/.ssh"
  chmod 740 "$HOME/.ssh"
  sudo sed -i.bak s/\#PasswordAuthentication\ yes/PasswordAuthentication\ yes/ /etc/ssh/sshd_config \
  &&  sudo systemctl enable ssh && sudo systemctl start ssh
  if [[ "$newkeypair" = "true" ]]; then
    #ssh-keygen -t rsa && ssh-add
    ssh-keygen -b 4096 -q -t rsa -P '' -f id_rsa && ssh-add
  else
    # set source perms to 600 for files
    cp -R --preserve=mode,timestamps --no-clobber "$bsdir/.ssh/id_*" "$HOME/.ssh/" && ssh-add
  fi
  install -m 600 /dev/null $HOME/.ssh/config
  echo -e \
    "ForwardX11Trusted yes\n
    ConnectTimeout 0\n\n
    Host localhost\n
    \s\sHostName $(hostname)\n\n
    Host *\n
    \s\sForwardX11 yes\n
    \s\sForwardAgent yes" >> $HOME/.ssh/config
};
function updatePi(){
  sudo apt --yes update \
  &&  sudo apt --yes upgrade \
  &&  sudo apt --yes install \
      htop \
      vim \
      terminator \
      nodejs \
      default-jdk \
      nodejs \
      code \
  && sudo apt --yes autoremove \
  && sudo rpi-eeprom-update -a
};
function installDocker(){
  local -r dget="https://get.docker.com"
  local -r dscr=".install-docker.sh"
  local -r chan="stable"
  curl -fsSL $dget -o $dscr && chmod 750 $dscr
  sh deploy-docker.sh --channel $chan #--dryrun
  if [[ $(sudo systemctl is-active --quiet docker) -eq 0 ]]; then
    sudo usermod -aG docker $USER
    if [[ $(sudo getent group docker | grep $USER) -eq 0 ]]; then
      local -r usergrps=$(id -g -n)
      log_info "$USER added to 'docker' grp.\n [ $usergrps ]"
      log_info "stage 00 complete for $HOSTNAME bootstrap."
      log_warn "rebooting in 15 seconds..." && sleep 5
      log_warn "rebooting in 10 seconds..." && sleep 5
      log_warn "rebooting in 5 seconds..." && sleep 5
      #shutdown -r now
    fi
  else
    log_error "docker service is not running after install."
    __die "${FUNCNAME[0]}: docker is not happy. bailing."
  fi
};
function fire(){
  mntUSB
  mkDirs
  confGit
  confSsh
  updatePi
  installDocker
};
fire
exit 0
