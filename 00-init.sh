#!/bin/bash
set -eu

## helpers
bold=""; reset="\e[0m"; green="\e[1;32m"; purple="\e[1;35m"; red="\e[1;31m"; yellow="\e[1;33m";
__wai=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);
__inet="$(sh -ic 'exec 3>&1 2>/dev/null; { curl --compressed -Is google.com 1>&3; kill 0; } | { sleep 10; kill 0; }' || :)";
__PROGNAME="${0##*/}";
__die(){ echo "${bold}${purple}${__PROGNAME}${reset}: error: $1" 1>&2; exit 1; };
__isnotempty(){ [ "$1" ] && return 0 || return 1; };
__validate_input(){ [ "$2" ] || __die "$1 requires an argument str"; };
__mkd(){ mkdir -p "$@" && cd "$_"; };
## logger
#__echo_stderr(){ >&2 echo "$@"; }; # stderr only
__echo_stderr(){ >&2 echo "$@" | tee $__wai/$(echo $0 | cut -d'.' -f1).log; }; # tee stderr to file
log(){ local -r level="$1"; local -r message="$2"; local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S"); local -r script_name="$(basename "$0")"; __echo_stderr -e "${timestamp} [${level}] [$script_name] ${message}"; };
log_info(){ local -r message="$1"; log "${bold}${green}INFO${reset}" "$message"; };
log_warn(){ local -r message="$1"; log "${bold}${yellow}WARN${reset}" "$message"; };
log_error(){ local -r message="$1"; log "${bold}${red}ERROR${reset}" "$message"; };
## bootstrap functions
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
    __mkd "$HOME/proj/github" \
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
  sudo raspi-config nonint do_ssh 0 # enable ssh in rpi config util
  __mkd "$HOME/.ssh" && chmod 740 "$HOME/.ssh"
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
  sudo apt --yes remove --purge \
    hicolor-icon-theme raspberrypi-artwork omxplayer penguinspuzzle \
  && sudo apt --yes autoremove
};
updatePi(){
  sudo apt --yes update \
  &&  sudo apt --yes upgrade \
  &&  sudo apt --yes install \
      usbmount htop vim terminator default-jdk nodejs code libasound2-dev\
  && sudo apt --yes autoremove \
  && sudo rpi-eeprom-update -a \
  && sudo raspi-config nonint do_update
};
confPyEnv(){
  # ref, https://www.raspberrypi.com/documentation/computers/os.html#use-python-on-a-raspberry-pi
  local -r venvdir="$HOME/.env";
  python -m venv --system-site-packages $venvdir \
  && source $venvdir/bin/activate
  ## venv context ##
  python -m pip list \
  && python -m pip install \
    sparkfun-qwiic \
    sparkfun-qwiic-as6212 \
    sparkfun-qwiic-proximity \
    sparkfun-top-phat-button \
    adafruit-circuitpython-neopixel \
    pyalsaaudio
    # ...
    # Arduino IDE v2 Install: https://docs.arduino.cc/software/ide-v2/tutorials/getting-started/ide-v2-downloading-and-installing/?_gl=1*190ql9d*_up*MQ..*_ga*MjAxMDI3NDMwNC4xNzM5OTA5ODk1*_ga_NEXN8H46L5*MTczOTkwOTg5NC4xLjEuMTczOTkxMDA1MS4wLjAuMzA1MjE0NDk.#linux

    # lib install: https://docs.arduino.cc/software/ide-v2/tutorials/ide-v2-installing-a-library/?_gl=1*16yvk8f*_up*MQ..*_ga*MjAxMDI3NDMwNC4xNzM5OTA5ODk1*_ga_NEXN8H46L5*MTczOTkwOTg5NC4xLjEuMTczOTkxMDA3NC4wLjAuMzA1MjE0NDk.

    # USB sink power sensor docs:
    # Lib > https://github.com/sparkfun/SparkFun_STUSB4500_Arduino_Library
    # hardware repo > https://github.com/sparkfun/Power_Delivery_Board-USB-C
  deactivate
  ## venv context ##
};
confQwiicSensors(){
  local -r dispdev="HDMI-1";
  local -r scardconf="/usr/share/alsa/alsa.conf";
  #https://www.raspberrypi.com/documentation/computers/configuration.html#underscan-nonint
  sudo raspi-config nonint do_overscan_kms $dispdev 1 # overscan (disable for topphat support)
  sudo raspi-config nonint do_vnc 1 # vnc server (disable)
  sudo raspi-config nonint do_rpi_connect 1 # rpi connect (disable)
  ## interfaces
  sudo raspi-config nonint do_spi 0 # spi kernel module (enable for topphat support)
  sudo raspi-config nonint do_i2c 0 # i2c kernel module (enable for topphat support)
  # audio codec (topphat)
  git clone https://github.com/waveshare/WM8960-Audio-HAT \
  && cd WM8960-Audio-HAT
  sudo bash install.sh # reboot is needed for changes to take effect.
  # verify after reboot with:
  # $ sudo dkms status
  #   ex. retval: wm8960-soundcard, 1.0, 4.19.66-v7+, arm7l: installed
  # sound card settings (topphat speaker)
  sudo sed -i.bak "s/defaults.ctl.card *.*/defaults.ctl.card 0/" $scardconf \
  && sudo sed -i.bak "s/defaults.pcm.card *.*/defaults.pcm.card 0/" $scardconf \
  && sudo sed -i.bak "s/defaults.pcm.device *.*/defaults.pcm.device 0/" $scardconf
  # display overlay for 5.4+ kernel
  # download > https://cdn.sparkfun.com/assets/learn_tutorials/1/1/7/0/sfe-topphat-overlay.dts
  dtc -@ -I dts -O dtb -o rpi-display.dtbo sfe-topphat-overlay.dts # compile
  sudo cp rpi-display.dtbo /boot/overlays # copy binary to device tree dir
  sudo echo -e 'dtoverlay=rpi-display,speed=32000000,rotate=270' >> /boot/config.txt # enable overlay
  # need to reboot to take effect
  ##
  # Temp sensor examples:
  # _ # https://github.com/sparkfun/Qwiic_AS6212_Py # https://learn.sparkfun.com/tutorials/digital-temperature-sensor-breakout---as6212-qwiic-hookup-guide/qwiic-as6212-python-package # https://learn.sparkfun.com/tutorials/digital-temperature-sensor-breakout---as6212-qwiic-hookup-guide/python-examples
  ##

};
installDocker(){
  __mkd "$HOME/.scripts"
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
confPostInit(){
  __mkd "$HOME/.scripts"
  local -r remote='https://raw.githubusercontent.com/datamonk/milhouse-init';
  local -r branch='main';
  local -r extp="/path/to/ext/partition";
  local -r fatp="/path/to/FAT/boot/partition";
  local initdarr=( 01-init.d_bootstrap 01-init.d_bootstrap.sh update-boot-partition.sh )
  for art in "${initdarr[@]}"; do
    if [[ $art =~ "update" ]]; then
      curl -fsSL $remote/refs/heads/$branch/$art | sudo bash -s EXT=$extp FAT=$fatp
    else
      curl -fsSL $remote/refs/heads/$branch/$art && chmod 750 $art
    fi
  done
};
confPiOsMisc()){
  local -r rpiconf="/usr/bin/raspi-config";
  local -r klpath="/etc/default/keyboard";
  local -r model="pc98"; # this layout has issues w/ rk-royal 98k
  local -r layout="us";
  sudo sed -i.bak "s/^XKBMODEL=*.*/XKBMODEL=\"$model\" /" $klpath
  sudo sed -i.bak "s/^XKBLAYOUT=*.*/XKBLAYOUT=\"$layout\" /" $klpath
  #sudo raspi-config nonint do_configure_keyboard <keymap>
  sudo raspi-config nonint do_boot_behaviour B2 # B2 = console w/ auto login
  sudo raspi-config nonint do_boot_wait 1 # wait until network interface is up before post boot occurs
  sudo raspi-config nonint do_leds 0 # builtin led triggers on disk i/o
  sudo raspi-config nonint do_change_locale en_GB.UTF-8 # set locale
  sudo raspi-config nonint do_change_timezone America/New_York # set timezone
  sudo sed -i.bak '/do_finish()/,/^$/!d' $rpiconf | sudo sed -e '1i ASK_TO_REBOOT=0;' -e '$a do_finish' | bash # fake out to avoid prompting for reboot
  sudo usermod -aG gpio $USER # ensure $USER is member of gpio grp
};
bounce(){
  log_warn "rebooting in 15 seconds..." && sleep 5
  log_warn "rebooting in 10 seconds..." && sleep 5
  log_warn "rebooting in 5 seconds..." && sleep 5
  shutdown -r now
};
run(){
  local -r reboot="false"; # boolean to reboot post 00-init
  [[ -z "$__inet" ]] && log_error "unable to connect to public domain." && __die "Check network settings.";
  for func in "${FUNCNAME[@]}"; do
    if [[ "$func" == ^"confwiFi"$ ]]; then
      log_warn "skipping [$func] eval per static def."
      continue;
    elif [[ "$func" == ^"__"[a-z]* ]]; then
      continue; # skipping helpers prepended w/ '__'
    elif [[ "$reboot" = "false" ]] && [[ "$func" = "bounce" ]]; then
      break; # bail prior to reboot
    fi
    log_info "starting [$func] eval" \
    && eval $func;
  done
};
run
exit 0
