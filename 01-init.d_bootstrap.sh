#!/bin/bash
#
# /boot/01-init.d_bootstrap.sh

# This script is executed by /etc/init.d/$initfn
#
# By default this script does nothing, and removes itself after the
# first run when called by /etc/init.d/$initfn

# This setting will cause this script to exit if there are any errors.
set -eu

disable_after_first_run(){
  #local -r init_fname='01-init.d_bootstrap';
  if [[ $CALLED_BY == init && $0 == /boot/01-init.d_bootstrap.sh ]]; then
    mv $0 $0.removed_after_first_run
    update-rc.d 01-init.d_bootstrap remove
  fi
}



bash $HOME/proj/github/hamster-cannon/raspi/init.d/01-init.d_bootstrap.sh

# If you want this script to remain and run at ever boot comment out the next line.
disable_after_first_run
