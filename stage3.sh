#!/usr/bin/env bash

echo -e "\e[1m\e[46m\e[97mSTAGE 3 ACTIVATED\e[0m"

if [ -f /archify-config/wheel_users ]; then
  while IFS="" read -r p || [ -n "$p" ]
  do
    echo -e "\e[1m\e[46m\e[97mADD USER $p TO GROUP wheel\e[0m"
    usermod -a -G wheel "$p"
  done < /archify-config/wheel_users

  echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/00_wheel
fi

if [ -f /archify-config/passwd_delta ]; then
  while IFS="" read -r p || [ -n "$p" ]
  do
    IFS=':' read -r -a arr <<< "$p"
    echo -e "\e[1m\e[46m\e[97mCHOWN HOME DIRECTORY ${arr[5]} FOR USER ${arr[0]}\e[0m"
    chown -R "${arr[0]}:${arr[0]}" "${arr[5]}" 
  done < /archify-config/passwd_delta
fi

source /archify-config/config

echo -e "\e[1m\e[46m\e[97mPERFORMING BASIC CONFIGURATION\e[0m"
ln -sf "/usr/share/zoneinfo/$LOCALTIME" /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen
echo "$NEWHOSTNAME" > /etc/hostname

if [[ -n "$NEW_NONSPACE_PASSWORD" ]]; then
  echo "root:$NEW_NONSPACE_PASSWORD" | chpasswd
fi

if [ "$SET_SPACE_PASSWORD" -eq 1  ]; then
  echo "root: " | chpasswd
fi

rm -rf /boot/*

# install DRACUT and pacman hooks for it
if [ "$DRACUT" -eq 1  ]; then
  echo -e "\e[1m\e[40m\e[93mINSTALLING DRACUT AND LVM2\e[0m"
  pacman --noconfirm -S lvm2 mdadm dracut

  echo -e "\e[1m\e[40m\e[93mINSTALL DRACUT HOOKS\e[0m"

  install -Dm644 /archify-config/90-dracut-install.hook /usr/share/libalpm/hooks/90-dracut-install.hook
  install -Dm644 /archify-config/60-dracut-remove.hook /usr/share/libalpm/hooks/60-dracut-remove.hook
  install -Dm755 /archify-config/dracut-install /usr/share/libalpm/scripts/dracut-install
  install -Dm755 /archify-config/dracut-remove /usr/share/libalpm/scripts/dracut-remove
  
  echo -e "\e[1m\e[40m\e[93mINSTALL KERNEL AND RUN DRACUT HOOKS\e[0m"
  pacman --noconfirm -Rns mkinitcpio
fi

pacman --noconfirm -S linux linux-firmware

if [[ $GRAPHICS_DRIVER != "no" ]]; then
  echo -e "\e[1m\e[46m\e[97mINSTALLING GRAPHICS DRIVER\e[0m"
  if [[ "$GRAPHICS_DRIVER" == "amd" ]]; then
    pacman --noconfirm -S libva-mesa-driver mesa vulkan-radeon xf86-video-amdgpu xf86-video-ati xorg-server xorg-xinit
  elif [[ "$GRAPHICS_DRIVER" == "intel" ]]; then
    pacman --noconfirm -S intel-media-driver libva-intel-driver mesa vulkan-intel xorg-server xorg-xinit
  elif [[ "$GRAPHICS_DRIVER" == "nouveau-nvidia" ]]; then
    pacman --noconfirm -S libva-mesa-driver mesa vulkan-nouveau xf86-video-nouveau xorg-server xorg-xinit
  elif [[ "$GRAPHICS_DRIVER" == "nvidia" ]]; then
    pacman --noconfirm -S libva-nvidia-driver nvidia xorg-server xorg-xinit
  elif [[ "$GRAPHICS_DRIVER" == "nvidia-open" ]]; then
    pacman --noconfirm -S libva-nvidia-driver nvidia-open xorg-server xorg-xinit
  elif [[ "$GRAPHICS_DRIVER" == "virt-machine" ]]; then
    pacman --noconfirm -S mesa xf86-video-vmware xorg-server xorg-xinit
  else
    pacman --noconfirm -S intel-media-driver libva-intel-driver libva-mesa-driver mesa vulkan-intel vulkan-nouveau vulkan-radeon xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xf86-video-vmware xorg-server xorg-xinit
  fi
fi

if [[ $SOUND_SERVER != "no" ]]; then
  echo -e "\e[1m\e[46m\e[97mINSTALLING SOUND SERVER\e[0m"
  if [[ "$SOUND_SERVER" == "pipewire" ]]; then
    pacman --noconfirm -S pipewire
  elif [[ "$SOUND_SERVER" == "pulseaudio" ]]; then
    pacman --noconfirm -S pulseaudio
  fi
fi

if [[ $GRAPHIC != "no" ]]; then

  # delete themes and other garbage from the old system
  for d in /home/*/ ; do
    echo "$d"
    rm -rf "$d/.config/dconf"
    rm -rf "$d/.config/gtk-3.0"
    rm -rf "$d/.config/gtk-4.0"
    rm -rf "$d/.cache/*"

    rm -rf "$d/.local/share/themes"
    rm -rf "$d/.local/share/icons"

    rm -rf "$d/.themes"
    rm -rf "$d/.icons"
  done

  pacman --noconfirm -S htop iwd nano openssh smartmontools wget wireless_tools man-db man-pages

  echo -e "\e[1m\e[46m\e[97mINSTALLING GRAPHICAL ENVIRONMENT\e[0m"
  if [[ "$GRAPHIC" == "gnome" ]]; then
    pacman --noconfirm -S gnome gnome-tweaks
    systemctl enable gdm
  elif [[ "$GRAPHIC" == "kde" ]]; then
    pacman --noconfirm -S plasma plasma-meta plasma-workspace kio-admin spectacle gwenview kcalc sddm kde-applications
    systemctl enable sddm
  elif [[ "$GRAPHIC" == "xfce4" ]]; then
    pacman --noconfirm -S xfce4 xfce4-goodies xarchiver pavucontrol gvfs lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "awesome" ]]; then
    pacman --noconfirm -S alacritty awesome feh gnu-free-fonts slock terminus-font ttf-liberation xorg-server xorg-xinit xorg-xrandr xsel xterm gdm
    systemctl enable gdm
  elif [[ "$GRAPHIC" == "bspwm" ]]; then
    pacman --noconfirm -S bspwm dmenu rxvt-unicode sxhkd xdo lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "budgie" ]]; then
    pacman --noconfirm -S arc-gtk-theme budgie mate-terminal nemo papirus-icon-theme lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "cinnamon" ]]; then
    pacman --noconfirm -S blueman bluez-utils cinnamon engrampa gnome-keyring gnome-screenshot gnome-terminal gvfs-smb system-config-printer xdg-user-dirs-gtk xed lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "cutefish" ]]; then
    pacman --noconfirm -S cutefish noto-fonts sddm
    systemctl enable sddm
  elif [[ "$GRAPHIC" == "deepin" ]]; then
    pacman --noconfirm -S deepin deepin-editor deepin-terminal lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "enlightenment" ]]; then
    pacman --noconfirm -S englightenment terminology lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "hyprland" ]]; then
    pacman --noconfirm -S dolphin dunst grim hyprland kitty polkit-kde-agent qt5-wayland qt6-wayland slurp wofi xdg-desktop-portal-hyprland xdg-utils sddm
    systemctl enable sddm
  elif [[ "$GRAPHIC" == "lxqt" ]]; then
    pacman --noconfirm -S breeze-icons leafpad lxqt oxygen-icons slock ttf-freefont xdg-utils sddm
    systemctl enable sddm
  elif [[ "$GRAPHIC" == "mate" ]]; then
    pacman --noconfirm -S mate mate-extra lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "qtile" ]]; then
    pacman --noconfirm -S alacritty qtile lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "sway" ]]; then
    pacman --noconfirm -S brightnessctl dmenu foot grim pavucontrol polkit slurp sway swaybg swayidle swaylock waybar xorg-xwayland xdg-utils lightdm lightdm-gtk-greeter
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "i3wm" ]]; then
    pacman --noconfirm -S dmenu i3-wm i3blocks i3lock i3status lightdm lightdm-gtk-greeter xss-lock xterm
    systemctl enable lightdm
  elif [[ "$GRAPHIC" == "fluxbox" ]]; then
    pacman --noconfirm -S fluxbox xterm xorg-server xorg-xinit
  elif [[ "$GRAPHIC" == "xorg" ]]; then
    pacman --noconfirm -S xorg-server xorg-xinit 
  fi
fi

if [ "$NETWORKMANAGER" -eq 1  ]; then
  echo -e "\e[1m\e[46m\e[97mINSTALLING NETWORKMANAGER\e[0m"
  pacman --noconfirm -S networkmanager
  systemctl enable NetworkManager
fi

CPU_VENDOR=$( sed -n '/vendor_id/{s/^[^:]*: *//;p;q}' /proc/cpuinfo )

if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
  pacman --noconfirm -S intel-ucode
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
  pacman --noconfirm -S amd-ucode
fi

echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

if [ -d /sys/firmware/efi ]; then
  echo -e "\e[1m\e[46m\e[97mINSTALLING GRUB (UEFI)\e[0m"
  env -i grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCHGRUB || env -i grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCHGRUB
else
  dev=$(findmnt -n -o SOURCE /boot | sed 's/ .*//;s/\/dev\///;s/\[.*//') 
  if [ -z "$dev" ]; then
    dev=$(findmnt -n -o SOURCE / | sed 's/ .*//;s/\/dev\///;s/\[.*//') 
  fi
  target=$(basename "$(readlink -f "/sys/class/block/$dev/..")")

  if [ -z "$target" ]; then
    echo -e "\e[1m\e[40m\e[93mCANNOT FIND DEVICE ON / FOR SOME REASON\e[0m"
    lsblk
    read -p "Enter drive for GRUB installation (e.g. sda or nvme0n1): " -r target

  fi


  echo -e "\e[1m\e[46m\e[97mINSTALLING GRUB (BIOS) ON $target\e[0m" 
  env -i grub-install --target=i386-pc "/dev/$target"
  cp -r /usr/lib/grub/i386-pc /boot/grub
fi

echo -e "\e[1m\e[46m\e[97mCREATING GRUB CONFIG\e[0m"
env -i grub-mkconfig -o /boot/grub/grub.cfg

sync

if [[ "$FORCE_REBOOT_AFTER_INSTALLATION" != "1" ]]; then
  echo -e "\e[1m\e[46m\e[97mSTARTING BASH TO PERFORM MANUAL POST-INSTALL CONFIGURATION\e[0m"
  echo -e "EXIT TO REBOOT"
  bash
fi

echo -e "\e[1m\e[46m\e[97mREBOOTING SYSTEM NOW\e[0m"
sleep 2

sync
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
