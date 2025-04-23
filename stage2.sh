#!/usr/bin/env bash

echo -e "\e[1m\e[46m\e[97mSTAGE 2 ACTIVATED\e[0m"


cd /host-system || exit 1

source /host-system/archify-config/config

echo 'nameserver 1.1.1.1' > /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

echo -e "\e[1m\e[46m\e[97mSETTING UP PACMAN\e[0m"
pacman-key --init
pacman-key --populate
cp /host-system/archify-config/mirrorlist.default /etc/pacman.d/mirrorlist
pacman -Sy

if [ "$REFLECTOR" -eq 1  ]; then
  echo -e "\e[1m\e[46m\e[97mINSTALLING REFLECTOR\e[0m"
  pacman --noconfirm -S reflector

  echo -e "\e[1m\e[46m\e[97mRUNNING REFLECTOR (it will take some time)\e[0m"
  reflector --latest 50 --protocol https --sort score --save /etc/pacman.d/mirrorlist
fi


echo -e "\e[1m\e[41m\e[97mDESTROYING HOST SYSTEM IN 5 SECONDS\e[0m"

for i in 5 4 3 2 1; do
  printf "%s..." "$i"
  sleep 1
done
printf "\n"

echo -e "\e[1m\e[41m\e[97mDESTROYING HOST SYSTEM\e[0m"
rm -rf bin etc lib lib64 sbin srv usr var
echo -e "\e[1m\e[41m\e[97mHOST SYSTEM DESTROYED\e[0m"

cd /

echo -e "\e[1m\e[46m\e[97mINSTALLING BASE SYSTEM\e[0m"
pacstrap -K /host-system base grub fastfetch sudo vim efibootmgr xfsprogs btrfs-progs dhcpcd wpa_supplicant bash-completion

echo -e "\e[1m\e[46m\e[97mCOPYING FSTAB\e[0m"

cp /host-system/archify-config/fstab /host-system/etc/fstab
cp /host-system/archify-config/crypttab /host-system/etc/crypttab

chmod +x /host-system/archify-config/stage3.sh

if [ -f /host-system/archify-config/passwd_delta ]; then
  echo -e "\e[1m\e[46m\e[97mCONFIGURING USERS\e[0m"

  for word in passwd shadow group gshadow; do
    wrd=$(tail -n+2 /host-system/etc/${word})
    echo -e "$(grep '^root:' /host-system/archify-config/${word}_delta)\n$wrd\n$(grep -v '^root:' /host-system/archify-config/${word}_delta)\n" | grep "\S" > /host-system/etc/${word}
  done
fi

echo -e "\e[1m\e[46m\e[97mEXECUTING CHROOT TO NEW SYSTEM\e[0m"
arch-chroot /host-system /archify-config/stage3.sh || echo -e "\e[1m\e[41m\e[97mOOOPS... CANNOT CHROOT TO NEW SYSTEM\!\e[0m"
echo "Dropping to shell. Note that you are in chroot and your old system is destroyed."
bash
