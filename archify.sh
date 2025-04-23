#!/usr/bin/env bash


cat << EOF

  █████╗ ██████╗  ██████╗██╗  ██╗██╗███████╗██╗   ██╗
 ██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔════╝╚██╗ ██╔╝
 ███████║██████╔╝██║     ███████║██║█████╗   ╚████╔╝ 
 ██╔══██║██╔══██╗██║     ██╔══██║██║██╔══╝    ╚██╔╝  
 ██║  ██║██║  ██║╚██████╗██║  ██║██║██║        ██║   
 ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   

 Ver 1.0
 Copyright (C) 2025 HardRaple ( github.com/hardraple/archify )

 Archify is a fork of Turboarch
 Copyright (C) 2024 Evgeny Vasilievich LINUX PIMP ( github.com/evgvs/turboarch )

EOF

if [ "$EUID" -ne 0 ]; then 
  echo "Run as root!"
  exit 1
fi

copy_user_configuration() {

  UID_MIN=$(grep '^UID_MIN' /etc/login.defs | sed 's/[^0-9]//g')
  UID_MAX=$(grep '^UID_MAX' /etc/login.defs | sed 's/[^0-9]//g')

  touch wheel_users
  echo "Found user: root"
  getent passwd root  > passwd_delta
  getent shadow root  > shadow_delta
  getent group root   > group_delta
  getent gshadow root > gshadow_delta

  normaluid=1000

  for d in $(getent passwd | awk -F: "(\$3 >= $UID_MIN && \$3 <= $UID_MAX) {printf \"%s\n\",\$1}") ; do

    IFS=':' read -r -a arr <<< "$(getent group "$d")"
    echo "${arr[0]}:${arr[1]}:$normaluid:${arr[3]}" >> group_delta

    IFS=':' read -r -a arr <<< "$(getent passwd "$d")"
    echo "${arr[0]}:${arr[1]}:$normaluid:$normaluid:${arr[4]}:${arr[5]}:${arr[6]}" >> passwd_delta

    if id -G -n "$d" | grep -qw 'sudo\|wheel'; then
      printf "Found user (sudo/wheel): %s", "$d"
      echo "$d" >> wheel_users
    else
      printf "Found user: %s", "$d"
    fi

    if [[ "${arr[2]}" != "$normaluid" ]]; then
      printf " (uid %s -> %s)" "${arr[2]}" "$normaluid"
    else
      printf " (uid %s)" "${arr[2]}"
    fi

    printf "\n"

    ((normaluid+=1))

    # getent shadow available only in glibc
    getent gshadow &> /dev/null
    if [[ "$?" == "1" ]]; then
      grep "^$d:" /etc/gshadow >> gshadow_delta
      grep "^$d:" /etc/shadow >> shadow_delta
    else
      getent gshadow "$d" >> gshadow_delta
      getent shadow "$d"  >> shadow_delta
    fi

  done
  SET_SPACE_PASSWORD=0
  NEW_NONSPACE_PASSWORD=""
}

if [ ! -f config.default ]; then
  read -p "Do you want to copy user configuration from current system? [Y/n] " -r yn
  if [[ $yn == [Nn]* ]]; then 
    password_confirmed=false
    SET_SPACE_PASSWORD=0
    read -p "Do you want to set ' ' password for root, i. e. space password [y/N] " -r yn
    if [[ $yn == [Yy]* ]]; then
      echo "Root password will be ' ', i. e. space"
      SET_SPACE_PASSWORD=1
      password_confirmed=true
    fi
    while [[ "$password_confirmed" != true ]]; do
      read -p "Set new password for root: " -r NEW_NONSPACE_PASSWORD
      read -p "New root password will be \"$NEW_NONSPACE_PASSWORD\", is it right? [Y/n] " -r yn
      if [[ $yn != [Nn]* ]]; then
        password_confirmed=true
      fi
    done
  else
    copy_user_configuration
  fi

  GRAPHICAL_ENVIRONMENTS=("gnome" "kde" "xfce4" "awesome" "bspwm" "budgie" "cinnamon" "cutefish" "deepin" "enlightenment" "hyprland" "lxqt" "mate" "qtile" "sway" "i3wm" "fluxbox" "xorg")
  NETWORKMANAGER=1

  while true; do
    echo "Available graphical environments: gnome kde xfce4 awesome bspwm budgie cinnamon cutefish deepin enlightenment hyprland lxqt mate qtile sway i3wm fluxbox xorg"
    read -p "Do you want to install one of these graphical environments? (type \"no\" to not install any) " -r yn
    if [[ $yn == "no" ]]; then 
      GRAPHIC="no"
    
      read -p "Do you want to use NetworkManager? [Y/n] " -r yn
      if [[ $yn == [Nn]* ]]; then 
        NETWORKMANAGER=0
      fi
    
      break
    else
      match=false
      for str in "${GRAPHICAL_ENVIRONMENTS[@]}"; do
        if [[ "$yn" == "$str" ]]; then
    	  match=true
    	  break
    	fi
      done
      if $match; then
        GRAPHIC="$yn"
        break
      fi
    fi
  done

  GRAPHICS_DRIVERS=("amd" "intel" "nouveau-nvidia" "nvidia" "nvidia-open" "virt-machine" "all-open")

  while true; do
    echo "Available graphics drivers: amd intel nouveau-nvidia nvidia nvidia-open virt-machine all-open"
    read -p "Choose one of them based on your GPU (type \"no\" to not install any) " -r yn
    if [[ $yn == "no" ]]; then 
      GRAPHICS_DRIVER="no"
      break
    else
      match=false
      for str in "${GRAPHICS_DRIVERS[@]}"; do
        if [[ "$yn" == "$str" ]]; then
    	  match=true
    	  break
    	fi
      done
      if $match; then
        GRAPHICS_DRIVER="$yn"
        break
      fi
    fi
  done

  SOUND_SERVERS=("pulseaudio" "pipewire")

  while true; do
    read -p "Do you want to install pipewire or pulseaudio as sound server (type \"no\" to not install any) " -r yn
    if [[ $yn == "no" ]]; then 
      SOUND_SERVER="no"
      break
    else
      match=false
      for str in "${SOUND_SERVERS[@]}"; do
        if [[ "$yn" == "$str" ]]; then
    	  match=true
    	  break
    	fi
      done
      if $match; then
        SOUND_SERVER="$yn"
        break
      fi
    fi
  done

  read -p "Set hostname for new system: [archlinux] " -r NEWHOSTNAME
  if [ -z "$NEWHOSTNAME" ]; then
    NEWHOSTNAME=archlinux
  fi

  LOCALTIME=$(cat /etc/timezone 2> /dev/null)
  if [ -z "$LOCALTIME" ]; then
    # in some strange distros timedatectl does not have operation show
    LOCALTIME="$(timedatectl | grep 'Time zone' | sed 's/.*Time zone: //;s/ .*//')"
    LOCALTIME="${LOCALTIME#*=}"
  fi
  if [ -z "$LOCALTIME" ]; then
    LOCALTIME="$(readlink -f /etc/localtime 2> /dev/null | sed 's/.*\/zoneinfo\///' )"
  fi
  if [ "$LOCALTIME" == "/etc/localtime" ]; then
    LOCALTIME="Europe/Moscow"
  fi
  if [ -z "$LOCALTIME" ]; then
    LOCALTIME="Europe/Moscow"
  fi
  read -p "Set timezone for new system in \"region/city\" format: [$LOCALTIME] " -r INPUTLOCALTIME
  if [ -n "$INPUTLOCALTIME" ]; then
    LOCALTIME=$INPUTLOCALTIME
  fi

  DRACUT=0
  if [[ $(dmsetup ls) != "No devices found" ]] && command -v dmsetup &> /dev/null; then 
    echo -e "\e[1m\e[40m\e[93mWARNING: CRAZY DISK CONFIGURATION FOUND (LUKS/LVM)\e[0m"
    echo -e "\e[1m\e[40m\e[93mNOTE THAT INITRAMFS WILL BE GENERATED BY DRACUT\e[0m"
    DRACUT=1
  else
    read -p "Do you want to use dracut instead of mkinitcpio to generate initramfs? Answer 'y' only if you have some unusual disk configuration with LUKS or LVM. [y/N] " -r yn
    if [[ $yn == [Yy]* ]]; then 
      DRACUT=1
    fi
  fi

  REFLECTOR=1
  read -p "Do you want to use reflector to select fastest mirrors? Otherwise, mirrors from 'mirrorlist.default' will be used. [Y/n] " -r yn
  if [[ $yn == [Nn]* ]]; then 
    REFLECTOR=0
  fi

  FORCE_REBOOT_AFTER_INSTALLATION=1
  read -p "Do you want to reboot after installation? [Y/n] " -r yn
  if [[ $yn == [Nn]* ]]; then 
    FORCE_REBOOT_AFTER_INSTALLATION=0
  fi

else
  source config.default
  echo "Using values from config.default"
  echo "Note that when using a prepared config, you must be sure that the values are correct"
  if [ "$COPY_USER_CONFIGURATION" -eq 1 ]; then
    copy_user_configuration
  fi
fi

echo "GRAPHIC=$GRAPHIC" > config
{
  echo "SET_SPACE_PASSWORD=$SET_SPACE_PASSWORD"
  echo "NEW_NONSPACE_PASSWORD=$NEW_NONSPACE_PASSWORD"
  echo "DRACUT=$DRACUT"
  echo "NETWORKMANAGER=$NETWORKMANAGER"
  echo "LOCALTIME=$LOCALTIME"
  echo "NEWHOSTNAME=$NEWHOSTNAME"
  echo "REFLECTOR=$REFLECTOR"
  echo "GRAPHICS_DRIVER=$GRAPHICS_DRIVER"
  echo "SOUND_SERVER=$SOUND_SERVER"
  echo "FORCE_REBOOT_AFTER_INSTALLATION=$FORCE_REBOOT_AFTER_INSTALLATION"
} >> config

set -e

if [ -d '/archlinux-bootstrap' ]; then
  echo 'Found /archlinux-bootstrap, using existing'
else
  echo 'Downloading archlinux-bootstrap'
  if command -v curl &> /dev/null; then
    curl -L -o archlinux-bootstrap.tar.zst https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst
  else
    wget -O archlinux-bootstrap.tar.zst https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst
  fi

  echo 'Extracting archlinux-bootstrap'
  tar -x -f archlinux-bootstrap.tar.zst -C /
  mv /root.x86_64 /archlinux-bootstrap
fi

echo "Mounting root to bootstrap"
mkdir -p /archlinux-bootstrap/host-system
mount --bind /archlinux-bootstrap /archlinux-bootstrap
mount --rbind / /archlinux-bootstrap/host-system
mount --bind /proc /archlinux-bootstrap/proc
mount --bind /sys /archlinux-bootstrap/sys
mount --bind /dev /archlinux-bootstrap/dev

mkdir -p /archify-config

cp stage2.sh /archlinux-bootstrap
cp stage3.sh /archify-config
chmod +x /archlinux-bootstrap/stage2.sh
chmod +x /archify-config/stage3.sh

set +e

if [ -f passwd_delta ]; then
  cp wheel_users /archify-config/wheel_users
  grep "\S" passwd_delta  > /archify-config/passwd_delta
  grep "\S" shadow_delta  > /archify-config/shadow_delta
  grep "\S" group_delta   > /archify-config/group_delta
  grep "\S" gshadow_delta > /archify-config/gshadow_delta
fi

cp mirrorlist.default /archify-config

cp /etc/fstab /archify-config
cp /etc/crypttab /archify-config

cp 90-dracut-install.hook /archify-config
cp 60-dracut-remove.hook /archify-config
cp dracut-install /archify-config
cp dracut-remove /archify-config

cp config /archify-config/config


dmesg -n 1

echo -e "\e[1m\e[46m\e[97mEXECUTING CHROOT TO ARCH BOOTSTRAP\e[0m"
if [[ $(tty) == /dev/tty* ]]; then
  env -i "$(command -v chroot)" /archlinux-bootstrap bash --init-file /etc/profile /stage2.sh
elif [[ -n "$SSH_CONNECTION" ]]; then
  echo -e "\e[1m\e[40m\e[93mInstalling via ssh seems like a bad idea. However, it will probably work but you will have to setup ssh manually after installation.\e[0m"
  env -i "$(command -v chroot)" /archlinux-bootstrap bash --init-file /etc/profile /stage2.sh
elif [[ "$FORCE_NO_OPENVT" == "1" ]]; then
  echo -e "\e[1m\e[40m\e[93mGot FORCE_NO_OPENVT option. As you wish...\e[0m"
  env -i "$(command -v chroot)" /archlinux-bootstrap bash --init-file /etc/profile /stage2.sh
else
  if command -v openvt &> /dev/null; then 
    openvt -c 13 -f -s -- env -i "$(command -v chroot)" /archlinux-bootstrap bash --init-file /etc/profile /stage2.sh
  else
    echo "Cannot run openvt. You should manually run this script in tty. If you believe that this is a mistake or you are running script from some kind of remote shell, run script with environment variable FORCE_NO_OPENVT=1"
  fi
fi
