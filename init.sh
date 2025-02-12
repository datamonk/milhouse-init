#!/bin/bash

function defs(){
  wai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);
  source $wai/.lib/src-libs.sh
  source $wai/.env

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

function mntUSB(){
  local -r usbdev='/dev/sda1';
  local -r usbmnt="/media/$USER/ORBITKEY";
  local -r mntuser="$USER";
  if [[ -b "$usbdev" ]]; then
  # sudo mount $usbdev $usbmnt -o uid=$mntuser,gid=$mntuser \
    bsdir="$usbmnt/hc/bootstrap"
    #log_info "USB media mounted at: [$(mount | grep $usbmnt)]"
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
  local -r gitemail="";
  local -r gituser="$USER";
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
  mkdir -p "~/.ssh" && chmod 740 "~/.ssh" && cd "~/.ssh";

  sudo sed -i.bak s/\#PasswordAuthentication\ yes/PasswordAuthentication\ yes/ /etc/ssh/sshd_config \
  &&  sudo systemctl enable ssh && sudo systemctl start ssh
  if [[ "$newkeypair" = "true" ]]; then
    #ssh-keygen -t rsa && ssh-add
    ssh-keygen -b 4096 -q -t rsa -P '' -f id_rsa && ssh-add
  else
    # set source perms to 600 for files
    cp --preserve=mode,ownership,timestamps --no-clobber "$bsdir/.ssh/*" "$HOME/.ssh/" \
    && ssh-add
  fi
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
  sudo ${WAI}/install-docker.sh --channel stable # --include-dryrun not working...
  if [[ $(docker_is_active) = 0 ]]; then
    sudo usermod -aG docker $USER
    if [[ $(is_docker_grp_member $USER) = 0 ]]; then
      log_info "$USER has successfully been added to docker group."
      log_warn "rebooting in 15 seconds..."
      sleep 5
      log_warn "rebooting in 10 seconds..."
      sleep 5
      log_warn "rebooting in 5 seconds..."
      sleep 5 && shutdown -r now
    fi
  else
    log_error "docker service is not running after installation."
    log_error "this issue needs to be addressed before proceeding."
    log_error "#######"
    sudo systemctl status docker && sudo systemctl status docker.socket
    log_error "#######"
  fi
};
function bounce(){
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
