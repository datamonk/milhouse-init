#!/bin/bash
set -eu

## helpers
bold=""; reset="\e[0m"; green="\e[1;32m"; purple="\e[1;35m"; red="\e[1;31m"; yellow="\e[1;33m"
__PROGNAME="${0##*/}";
__die(){ echo "${bold}${purple}${__PROGNAME}${reset}: error: $1" 1>&2; exit 1; };
__isnotempty(){ [ "$1" ] && return 0 || return 1; };
__validate_input(){ [ "$2" ] || __die "$1 requires an argument str"; };
wai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);
__inet="$(sh -ic 'exec 3>&1 2>/dev/null; { curl --compressed -Is google.com 1>&3; kill 0; } | { sleep 10; kill 0; }' || :)";
mkd(){ mkdir -p "$@" && cd "$_"; };
echo_stderr(){ >&2 echo "$@"; };
log(){ local -r level="$1"; local -r message="$2"; local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S"); local -r script_name="$(basename "$0")"; echo_stderr -e "${timestamp} [${level}] [$script_name] ${message}"; };
log_info(){ local -r message="$1"; log "${bold}${green}INFO${reset}" "$message"; };
log_warn(){ local -r message="$1"; log "${bold}${yellow}WARN${reset}" "$message"; };
log_error(){ local -r message="$1"; log "${bold}${red}ERROR${reset}" "$message"; };
## init functions
mntUSB(){
  local -r usbdev='/dev/sda1';
  if [[ -b "$usbdev" ]]; then
    usbmnt=$(mount | grep "$usbdev" | cut -d' ' -f3)
    if [[ $(__isnotempty $usbmnt) -eq 0 ]]; then
      log_info "existing $usbdev mnt found at [$usbmnt]"
    else
      usbmnt="/media/$USER/ORBITKEY";
      log_warn "$usbdev mnt point returned null. attempting to mnt at [$usbmnt]"
      sudo mount $usbdev $usbmnt -o uid=$USER,gid=$USER \
      && log_info "USB media mounted at: [$(mount | grep $usbmnt)]"
    fi
    bsdir="$usbmnt/hc/bootstrap";
    envpath="$bsdir/.env"
  else
    log_error "usb dev path not found."
    __die "${FUNCNAME[0]}: unable to mnt usb for secrets def. bailing."
  fi
};
confWiFi(){
    local -r wpaconf="/etc/wpa_supplicant/wpa_supplicant.conf";
    local -r ssid="$(cat $envpath | grep 'ssid' | cut -d':' -f2)";
    local -r ssid_pw="$(cat $envpath | grep 'ssid_pw' | cut -d':' -f2)";
    sudo cp "$wpaconf" "$wpaconf.bak" \
    && sudo wpa_passphrase "$ssid" "$ssid_pw" | tee -a $wpaconf \
    && sudo sed -i.bak 's/iface wlan0 inet manual/iface wlan0 inet dhcp/; s/wpa-roam/wpa-conf/; $i auto wlan0 eth0' /etc/network/interfaces
};
confGit(){
  local -r gitemail="$USER@gmail.com";
  local -r gitcreds="$bsdir/.git-token";
  local -r reposlug="datamonk/hamster-cannon.git";
  local -r reponame="$(basename "$reposlug" | cut -d'.' -f1)";
  local -r bsrepo="https://$(cat $gitcreds)@github.com/$reposlug";
  if [[ -f "$gitcreds" ]]; then
    log_info "Applying global setting for git env."
    git config --global user.email "$gitemail" \
    && git config --global user.name "$USER" \
    && git config --global credential.helper "store --file $HOME/.git-credentials"
    mkd "$HOME/proj/github" \
    && git clone "$bsrepo"
    if [[ ! -f "$HOME/proj/github/$reponame/README.md" ]]; then
      log_error "$reposlug repo clone failed."
      __die "${FUNCNAME[0]}: private tokenized repo clone failed and required to proceed. bailing."
    fi
  fi
};
confSsh(){
  local -r newkeypair="true";
  local -r sshdconf="/etc/ssh/sshd_config";
  mkd "$HOME/.ssh" && chmod 740 "$HOME/.ssh"
  sudo sed -i.bak s/\#PasswordAuthentication\ yes/PasswordAuthentication\ yes/ $sshdconf \
  && sudo sed -i.bak "s/PermitRootLogin *.*/PermitRootLogin No/" $sshdconf \
  && sudo systemctl enable ssh && sudo systemctl start ssh
  if [[ "$newkeypair" = "true" ]]; then
    ssh-keygen -b 4096 -q -t rsa -P '' -f id_rsa && ssh-add
  else
    cp -R --preserve=mode,timestamps --no-clobber "$bsdir/.ssh/id_*" "$HOME/.ssh/" && ssh-add
  fi
  install -m 600 /dev/null $HOME/.ssh/config
  echo -e "ForwardX11Trusted yes\nConnectTimeout 0\n\nHost localhost\n  HostName $(hostname)\n\nHost *\n  ForwardX11 yes\n  ForwardAgent yes" >> $HOME/.ssh/config
};
removeBloat(){
  sudo apt --yes remove --purge raspberrypi-artwork omxplayer penguinspuzzle
};
updatePi(){
  sudo apt --yes update \
  &&  sudo apt --yes upgrade \
  &&  sudo apt --yes install \
      usbmount htop vim terminator default-jdk nodejs code \
  && sudo apt --yes autoremove \
  && sudo rpi-eeprom-update -a
};
installDocker(){
  mkd "$HOME/.scripts"
  local -r dget="https://get.docker.com";
  local -r dscr="install-docker.sh";
  local -r chan="stable";
  curl -fsSL $dget -o $dscr && chmod 750 $dscr
  sh $dscr --channel $chan #--dryrun
  if [[ $(sudo systemctl is-active --quiet docker) -eq 0 ]]; then
    sudo usermod -aG docker $USER
    log_info "$USER added to docker grp."
  else
    log_error "docker service is not running after install."
    __die "${FUNCNAME[0]}: docker is not happy. bailing."
  fi
};
confKeyboard(){
  local -r klpath="/etc/default/keyboard";
  local -r model="pc98"; # this layout has issues w/ rk-royal 98k
  local -r layout="us";
  sudo sed -i.bak "s/^XKBMODEL=*.*/XKBMODEL=\"$model\" /" $klpath
  sudo sed -i.bak "s/^XKBLAYOUT=*.*/XKBLAYOUT=\"$layout\" /" $klpath
};
fakeOutRaspiConfig(){
  local -r rpiconf="/usr/bin/raspi-config";
  sudo sed -i.bak '/do_finish()/,/^$/!d' $rpiconf | sudo sed -e '1i ASK_TO_REBOOT=0;' -e '$a do_finish' | bash
};
bounce(){
  log_warn "rebooting in 15 seconds..." && sleep 5
  log_warn "rebooting in 10 seconds..." && sleep 5
  log_warn "rebooting in 5 seconds..." && sleep 5
  shutdown -r now
};
execInit(){
  mntUSB
  confWiFi
  [[ -z "$__inet" ]] && log_error "unable to connect to public domain." \
    && __die "${FUNCNAME[0]}: Check network settings. bailing.";
  confGit
  confSsh
  removeBloat
  updatePi
  installDocker
  confKeyboard
  log_info "00-init stage complete for $HOSTNAME."
  fakeOutRaspiConfig
  bounce
};
execInit && exit 0
