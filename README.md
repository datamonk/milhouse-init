# milhouse-init
Exposed scripts/configs to bootstrap PiOS vanilla image.

This repo was developed/tested against PiOS (bookworm armhf image - 2024-11-19 release) using a RPI 5 (8gb) coupled with a PCIe/PoE+ hat. Otherwise everything was left un-modified.

The one detail to note is that since I'm using PoE+ to provide both power and network connectivity from an already established lab environment, I purposely left out any configuration changes from the default network interface(s) settings to include WiFi. At some point I may add the ability to set a static address but a DHCP reservation should do the trick for any exposed services from this node.

Official download URL: https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf.img.xz

```
# execute via bundled script from local /dev/sda1 mount point.
bash `mount | grep "/dev/sda1" | cut -d' ' -f3`/hc/bs.sh
```
```
# execute manually
cd ~ && curl -fsSL https://raw.githubusercontent.com/datamonk/milhouse-init/refs/heads/main/00.sh | bash
```
