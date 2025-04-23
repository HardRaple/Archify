# Archify - Seamlessly replace your current distribution with Arch Linux
This script allows you to replace any Linux distribution with Arch Linux, preserving user data and providing extensive configuration options for the new system. The script will also be useful if your VPS provider allows system changes but does not provide Arch Linux image or custom image uploads.

## Quick start
Download and run required scripts:
```
git clone https://github.com/hardraple/archify
cd archify
sudo bash archify.sh
```
This will ask some questions and begin Arch Linux installation. Data in `/home`, disk configuration (even with LVM and LUKS!), user accounts and passwords, sudo/wheel group will be preserved. Additionally, you can install one of many graphical environments, choose graphics driver and audio server. It is also possible to use a configuration file to save parameters and automation.

> [!IMPORTANT]
> Everything in `/bin`, `/boot`, `/etc`, `/lib`, `/lib64`, `/sbin`, `/srv`, `/usr` and `/var` will be permanently removed. Make a backup of the files you need from these folders, such as configuration files and virtual machine snapshots. Other directories will not be affected at all, and no partitions will be formatted.

## Requirements
* Internet connection
* x86_64 Linux kernel version suitable for glibc in Arch Linux (3.2+ for glibc version 2.39)
* `grep`, `coreutils` and `util-linux`
* `bash` version 4+
* `wget` or `curl` and to download Arch Linux bootstrap, `tar` and `zstd` to decompress bootstrap archive. You can also manually download and extract [bootstrap archive](https://geo.mirror.pkgbuild.com/iso/latest/) to `/archlinux-bootstrap`

## Installation process explained
### Stage 1 (archify.sh)
* The script copies needed files to safe place where they will not be removed
* Downloads Arch Linux rootfs and extracts it to `/archlinux-bootstrap`
* Recursively mounts root to directory `host-system` inside `/archlinux-bootstrap` (`mount --rbind / /archlinux-bootstrap/host-system`)
* Mounts `/sys`, `/dev` and `/proc` to corresponding directories inside `/archlinux-bootstrap`
* Copies `stage2.sh` to `/archlinux-bootstrap`, chroots and runs the script

### Stage 2
* Removes everything in `/host-system/{bin, boot, etc, lib...}`
* Installs the base system with `pacstrap`
* Copies fstab and users configuration to new system
* Chroots to `/host-system` and runs `stage3.sh`

### Stage 3
* Configures locale, hostname and time
* Installs kernel and generates initramfs
* Installs chosen graphics driver, sound server, graphical environment
* Installs and configures GRUB
* Reboots or redirects you to bash

## FAQ & Fine tuning

### Change mirrors
Edit the `mirrorlist.default` file to change the mirrors. If reflector is enabled, that mirrors will only be used to download python and reflector. 

### SSH
Installing via ssh seems like a bad idea. However, it will probably work but you will have to setup ssh manually after installation. Script will detect `$SSH_CONNECTION` and proceed to installation. If you are running script from some another remote shell, set environment variable `FORCE_NO_OPENVT=1`.

### Preconfigure
To preconfigure the script, create a file called `config.default`, here's an example:
```
COPY_USER_CONFIGURATION=1
GRAPHIC="gnome"
SET_SPACE_PASSWORD=1
NEW_NONSPACE_PASSWORD="Will be overriden by 1) COPY_USER_CONFIGURATION 2) SET_SPACE_PASSWORD"
DRACUT=0
NETWORKMANAGER=1
LOCALTIME="Europe/Monaco"
NEWHOSTNAME="archify"
REFLECTOR=1
GRAPHICS_DRIVER="all-open"
SOUND_SERVER="no"
FORCE_REBOOT_AFTER_INSTALLATION=1
```
If `COPY_USER_CONFIGURATION` is set to 1, script will try to copy user configuration from files `wheel_users`, `passwd_delta`, `shadow_delta`, `group_delta`, `gshadow_delta` and any password parameters will be ignored. If `SET_SPACE_PASSWORD` is set to 1 and `COPY_USER_CONFIGURATION` is set to 0, root password will be ' ', i. e. space and `NEW_NONSPACE_PASSWORD` will be ignored. If `COPY_USER_CONFIGURATION` and `SET_SPACE_PASSWORD` are set to 0, then `NEW_NONSPACE_PASSWORD` value will be used as root password.

`wheel_users` contains list of users (one per line) that will be added to `wheel` group. This implies creation of `%wheel ALL=(ALL:ALL) ALL` rule in sudoers.

`passwd_delta`, `shadow_delta`, `group_delta`, `gshadow_delta` contains corresponding lines from getent. Example:
```
$ getent passwd pimp | tee -a passwd_delta
pimp:x:1000:1000::/home/pimp:/usr/bin/bash
$ getent shadow pimp | tee -a shadow_delta
pimp:$y$j9T$LuhFnrcezH0TUA1GaUqwa/$Ptme335MkS61UIlNQ.0jRD1doz7zQFzKIQcP6MXW6O1:19729:0:99999:7:::
```

### Tested distributions
Сhanges in Archify do not affect compatibility with distributions. Archify, as Turboarch, works successfully on the following distributions:

* Manjaro
* Debian
* Ubuntu
* Fedora
* ROSA
* Astra
* Void
* Slackware
* Gentoo
* OpenSUSE
* Tiny Core

### I have /home, /var, /tmp, /lib, /usr/X11R6... on different partitions!
Archify basically just doesn't care about your partition scheme. All mountpoints will be transferred to the new system. 

### LVM & LUKS
It is supported, but if LVM or LUKS is detected, Archify will use DRACUT to generate initramfs. However, hooks for pacman will be installed, so DRACUT shouldn't be a big problem.

### ZFS
No, it is currently not supported.

### Graphics drivers
Select the driver that is intended for the GPU that is currently displaying the image. If necessary, you can install other drivers yourself after switching to Arch Linux.

### GRUB
On BIOS, GRUB will be installed to device that has partition that is mounted to `/boot` or `/`. On UEFI, GRUB will be installed to `/boot` or `/boot/efi`. OS-PROBER will be enabled by default.

### Why locale is set to en_US.UTF-8?
Other locale requires fonts to be configured and this can cause problems with displaying characters in various parts of the system. In linux it is generally better to use only this locale to avoid errors.


Archify is a fork of Turboarch. For additional information, see [Turboarch github page](https://github.com/evgvs/turboarch)