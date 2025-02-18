#!/usr/bin/env bash

# This is a tool I use for applying this package to an imaged SD card.
# it is my hope that this gets baked into Raspbian and all that is needed is editing the /boot/$init_fname.sh

local -r init_fname='01-init.d_bootstrap';
if [[ ! ( # any of the following are not true
  -d "$EXT" &&
  -d "$FAT" &&
  $(sudo id -u) -eq 0 &&
  $(sudo id -g) -eq 0
  ) ]];
then
  echo "    Usage: EXT=/path/to/ext/partition FAT=/path/to/FAT/boot/partition $(basename "$0")"
  echo "    Must run as root (id 0, group 0)"
  exit 1;
fi

ln -s "../init.d/$init_fname" "$EXT/etc/rcS.d/S10$init_fname"
cp "$init_fname" "$EXT/etc/init.d/$init_fname"
cp "$init_fname.sh" "$FAT/$init_fname.sh"
#echo check ownership of...
ls -l "$EXT/etc/rcS.d/S10$init_fname" "$EXT/etc/init.d/$init_fname" "$FAT/$init_fname.sh"
