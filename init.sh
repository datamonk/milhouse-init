#!/bin/bash

function defs(){
  __PROGNAME="${0##*/}"
  __die(){ echo "${__PROGNAME}: error: $1" 1>&2; exit 1; };
  __isnotempty(){ [ "$1" ] && return 0 || return 1; };
  __validate_input(){
     [ "$2" ] || __die "$1 requires an argument (container name)"
  #  example usage:
  #    __validate_input "${FUNCNAME[0]}" "$1"
  #    __isnotempty "$(container_id "$1")"
  };

};

if [[ $(id -u) -ne  0 ]]; then
  log_error "Bootstrap init needs root exec. uid = $(id -u)"
  exit 1
fi
function mntUSB(){
  local -r usbdev='/dev/sda1';
  local -r usbmnt='/mnt/usb';
  local -r mntuser='afcamar';
  if [[ -b "$usbdev" ]]; then
     sudo mount $usbdev $usbmnt -o uid=$mntuser,gid=$mntuser \
    && bsdir="$usbmnt/hc/bootstrap"
    log_info "USB media mounted at: [$(mount | grep $usbmnt)]"
  fi
};
function mkDirs(){
  mkdir -p "$HOME/proj/github" \
           "$HOME/proj/software" \
           "$HOME/data" \
           "$HOME/certs" \
           "$HOME/scripts" \
           "$HOME/tmp" \
           "$HOME/.secrets"
  cd $HOME \
  && ln -s proj/github gh \
  && ln -s proj/software sw \
  && ln -s .secrets .creds
};
function confGit(){
  local -r gitemail='acamara86@gmail.com';
  local -r gituser='Andy Camara';
  local -r gitcreds="$bsdir/.git-token";
  local -r bsrepo="https://$(cat $gitcreds)@github.com/datamonk/hamster-cannon.git";
  if [[ -f "$gitcreds" ]]; then
    log_info "Applying global setting for git env."
    git config --global user.email "$gitemail" \
    && git config --global user.name "$gituser" \
    && git config --global credential.helper "store --file $HOME/.git-credentials" \
    && git clone "$bsrepo"
  fi
};
function confSsh(){
  local -r newkeypair="true"; # false to cp from usb
  mkd(){
    mkdir -p "$@" && chmod 740 "$_" && cd "$_";
  };
  sudo sed -i.bak s/\#PasswordAuthentication\ yes/PasswordAuthentication\ yes/ /etc/ssh/sshd_config \
  &&  sudo systemctl start ssh
  if [[ "$newkeypair" = "true" ]]; then
    #ssh-keygen -t rsa && ssh-add
    ssh-keygen -b 4096 -q -t rsa -P '' -f id_rsa && ssh-add
  else
    # set source perms to 600 for files
    cp --preserve=mode,ownership,timestamps --no-clobber "$bsdir/.ssh/*" "$HOME/.ssh/" \
    && ssh-add
    install -m 600 /dev/null ${SSH_DIR}/config
    echo 'ForwardX11Trusted yes' >> ${SSH_DIR}/config
    echo 'ConnectTimeout 0' >> ${SSH_DIR}/config
    echo '' >> ${SSH_DIR}/config
    echo 'Host localhost' >> ${SSH_DIR}/config
    echo "  HostName $(hostname)" >> ${SSH_DIR}/config # note prefixed [spaces]
    echo '' >> ${SSH_DIR}/config
    echo 'Host *' >> ${SSH_DIR}/config
    echo '  ForwardX11 yes' >> ${SSH_DIR}/config
    echo '  ForwardAgent yes' >> ${SSH_DIR}/config
  fi
};
function updatePi(){
  sudo apt --yes update \
  &&  sudo apt --yes full-upgrade \
  &&  sudo apt --yes install \
      htop \
      vim \
      terminator \
      nodejs \
      default-jdk \
      nodejs \
  && sudo apt --yes autoremove \
  && sudo rpi-eeprom-update -a
};
function bounce(){
  echo "bootstrap-init stage done."
  echo "rebooting in 15 seconds..." && sleep 5
  echo "rebooting in 10 seconds..." && sleep 5
  echo "rebooting in 5 seconds..." && sleep 5
  shutdown -r now
};
function fire(){
  mntUSB
  mkDirs
  confGit
  confSsh
  updatePi
  bounce
};
fire
exit 0
